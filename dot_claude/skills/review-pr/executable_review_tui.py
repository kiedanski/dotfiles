#!/usr/bin/env python3
"""
review_tui.py — full-screen, vim-navigated PR review with a LIVE file pane.

Three columns:
  [ sections ]  [ notes ]  [ the real source file, opened on the side ]

As you move between sections/changes, the right pane opens the actual file from
the checked-out repo at the relevant line — you read real code in context, not a
frozen snippet. Everything scrolls inside the app (no mouse). Vim keys throughout.

Keys
  j / k        down / up in the focused pane (in the section list: move selection)
  h / l        move focus left / right  (sections -> notes -> file)
  Tab          cycle focus
  n / p        next / previous change ("open on the side") within a section
  ] / [        same as n / p
  g / G        top / bottom of the focused pane
  Ctrl-d / -u  half page down / up
  e            open the current file in $EDITOR at the line
  ?            help          q  quit

Reads review.json (schema in SKILL.md). Real-file view needs top-level
"repo_root" and per-target "path" (repo-relative) + "anchor" (a line to locate).
Stdlib only.

Usage: python3 review_tui.py <review.json> [--repo /path/to/checkout]
"""

import curses
import json
import os
import subprocess
import sys
import textwrap

# color pair ids
C_HEAD, C_ADD, C_DEL, C_NOTE, C_REF, C_DIM, C_MAG, C_LNUM, C_SEL, C_TITLE = range(1, 11)

TERM_EDITORS = {"vim", "nvim", "vi", "nano", "emacs", "helix", "hx", "kak"}


def _wrap(text, width):
    out = []
    for para in str(text).split("\n"):
        if not para.strip():
            out.append("")
            continue
        out.extend(textwrap.wrap(para, width=max(4, width)) or [""])
    return out


def _color_diff_line(line):
    if line.startswith("+") and not line.startswith("+++"):
        return C_ADD
    if line.startswith("-") and not line.startswith("---"):
        return C_DEL
    if line.startswith("@@"):
        return C_HEAD
    if line.startswith(("diff ", "index ", "+++", "---", "#")):
        return C_DIM
    return 0


class Pane:
    """A scrollable list of (text, color, attr) lines drawn in a column region."""

    def __init__(self, title):
        self.title = title
        self.lines = []           # list of (text, color_id, attr)
        self.off = 0

    def set(self, lines):
        self.lines = lines
        self.off = 0

    def _view_h(self, h):
        return max(1, h - 1)      # minus title row

    def clamp(self, h):
        maxoff = max(0, len(self.lines) - self._view_h(h))
        self.off = max(0, min(self.off, maxoff))

    def scroll(self, d, h):
        self.off += d
        self.clamp(h)

    def to(self, where, h):
        if where == "top":
            self.off = 0
        else:
            self.off = max(0, len(self.lines) - self._view_h(h))

    def draw(self, scr, y0, x0, w, h, focused):
        # title
        tcol = curses.color_pair(C_TITLE) | (curses.A_BOLD if focused else curses.A_DIM)
        bar = (" " + self.title).ljust(w)[:w]
        try:
            scr.addstr(y0, x0, bar, tcol | (curses.A_REVERSE if focused else 0))
        except curses.error:
            pass
        view = self._view_h(h)
        for i in range(view):
            idx = self.off + i
            y = y0 + 1 + i
            if idx >= len(self.lines):
                break
            text, color, attr = self.lines[idx]
            attr = attr or 0
            if color:
                attr |= curses.color_pair(color)
            s = text[: w - 1]
            try:
                scr.addstr(y, x0, s, attr)
            except curses.error:
                pass
        # scroll indicator
        if len(self.lines) > view:
            frac = self.off / max(1, len(self.lines) - view)
            marky = y0 + 1 + int(frac * (view - 1))
            try:
                scr.addstr(marky, x0 + w - 1, "█", curses.color_pair(C_DIM))
            except curses.error:
                pass


class ListPane(Pane):
    def __init__(self, title, items):
        super().__init__(title)
        self.items = items        # list of label strings
        self.sel = 0

    def move(self, d, h):
        self.sel = max(0, min(len(self.items) - 1, self.sel + d))
        view = self._view_h(h)
        if self.sel < self.off:
            self.off = self.sel
        elif self.sel >= self.off + view:
            self.off = self.sel - view + 1

    def draw(self, scr, y0, x0, w, h, focused):
        tcol = curses.color_pair(C_TITLE) | (curses.A_BOLD if focused else curses.A_DIM)
        try:
            scr.addstr(y0, x0, (" " + self.title).ljust(w)[:w],
                       tcol | (curses.A_REVERSE if focused else 0))
        except curses.error:
            pass
        view = self._view_h(h)
        for i in range(view):
            idx = self.off + i
            if idx >= len(self.items):
                break
            y = y0 + 1 + i
            label = self.items[idx]
            marker = "❯ " if idx == self.sel else "  "
            s = (marker + label)[: w - 1].ljust(w - 1)
            attr = 0
            if idx == self.sel:
                attr = curses.A_REVERSE | (curses.A_BOLD if focused else 0)
            try:
                scr.addstr(y, x0, s, attr)
            except curses.error:
                pass


class App:
    def __init__(self, review, repo_root):
        self.r = review
        self.repo = repo_root
        self.notes_w, self.file_w = 44, 60   # provisional until first layout
        self._two_col_file = False
        self.entries = self._build_entries()
        labels = [e["label"] for e in self.entries]
        self.list = ListPane("SECTIONS", labels)
        self.notes = Pane("NOTES")
        self.filep = Pane("FILE")
        self.focus = 0            # index into visible focusable panes
        self.cur_target = 0
        self._file_cache = {}
        self.msg = ""
        self._load_entry()

    # ---- content model -------------------------------------------------
    def _build_entries(self):
        r = self.r
        entries = [{"kind": "overview", "label": "Overview"}]
        for i, s in enumerate(r.get("sections", []), 1):
            entries.append({"kind": "section", "label": f"{i}. {s.get('title','')}",
                            "section": s})
        files = r.get("files", [])
        if files:
            entries.append({"kind": "files_index",
                            "label": f"▤ All changed files ({len(files)})"})
            icon = {"added": "+", "deleted": "−", "modified": "~"}
            for f in files:
                parts = f["path"].split("/")
                short = "/".join(parts[-2:]) if len(parts) > 1 else parts[-1]
                lbl = f"  {icon.get(f['status'],'~')} {short}"
                entries.append({"kind": "file", "label": lbl, "file": f})
        if r.get("overall_questions"):
            entries.append({"kind": "questions", "label": "⚑ Open questions"})
        return entries

    def _targets(self, section):
        t = []
        for hnk in section.get("hunks", []):
            t.append({"kind": "change", "label": hnk.get("file", "change"),
                      "path": hnk.get("path"), "anchor": hnk.get("anchor"),
                      "note": hnk.get("note", ""), "body": hnk.get("diff", "")})
        for ref in section.get("references", []):
            t.append({"kind": "ref", "label": ref.get("label", "reference"),
                      "path": ref.get("path"), "anchor": ref.get("anchor"),
                      "note": ref.get("note", ""), "body": ref.get("snippet", "")})
        return t

    def _cur_entry(self):
        return self.entries[self.list.sel]

    def _file_targets(self, f):
        t = []
        for i, hnk in enumerate(f.get("hunks", []), 1):
            t.append({"kind": "change", "label": f"hunk {i} @ line {hnk.get('line', 1)}",
                      "path": f["path"], "line": hnk.get("line"),
                      "note": "", "body": hnk.get("diff", "")})
        return t

    def _cur_targets(self):
        e = self._cur_entry()
        if e["kind"] == "section":
            return self._targets(e["section"])
        if e["kind"] == "file":
            return self._file_targets(e["file"])
        return []

    def _load_entry(self):
        self.cur_target = 0
        e = self._cur_entry()
        self.notes.set(self._notes_lines(e))
        self._load_file()

    def _notes_lines(self, e):
        L = []
        A = lambda t="", c=0, at=0: L.append((t, c, at))
        if e["kind"] == "overview":
            A("THE GIST", C_HEAD, curses.A_BOLD)
            for ln in _wrap(self.r.get("gist", ""), self.notes_w):
                A("  " + ln)
            A()
            if self.r.get("map"):
                A("HOW IT FITS", C_HEAD, curses.A_BOLD)
                for m in self.r["map"]:
                    A(f"  {m.get('from','')}", C_MAG, curses.A_BOLD)
                    A(f"    → {m.get('action','')} {m.get('to','')}", C_NOTE)
                    if m.get("note"):
                        for ln in _wrap(m["note"], self.notes_w - 4):
                            A("      " + ln, C_DIM)
                    A()
            A("─ j/k move sections · l enter · pick a section ─", C_DIM)
        elif e["kind"] == "questions":
            A("OPEN QUESTIONS — for your judgment", C_HEAD, curses.A_BOLD)
            A("not bugs; prompts to test whether the approach feels right", C_DIM)
            A()
            for q in self.r.get("overall_questions", []):
                A("? ", C_NOTE, curses.A_BOLD)
                first = True
                for ln in _wrap(q, self.notes_w - 2):
                    A(("  " if first else "  ") + ln, C_NOTE)
                    first = False
                A()
        elif e["kind"] == "files_index":
            files = self.r.get("files", [])
            A("ALL CHANGED FILES", C_HEAD, curses.A_BOLD)
            A(f"{len(files)} files · every change is here (j/k in the list to open one)", C_DIM)
            A()
            icon = {"added": "+ ", "deleted": "− ", "modified": "~ "}
            for f in files:
                col = C_ADD if f["status"] == "added" else (
                    C_DEL if f["status"] == "deleted" else 0)
                A(icon.get(f["status"], "~ ") + f["path"][: self.notes_w - 2], col)
                meta = f"    +{f['additions']} −{f['deletions']}  ·  {len(f['hunks'])} hunk(s)"
                if f.get("blurb"):
                    meta += f"  ·  {f['blurb']}"
                for ln in _wrap(meta, self.notes_w - 2):
                    A(ln, C_DIM)
        elif e["kind"] == "file":
            f = e["file"]
            A(f["path"], 0, curses.A_BOLD)
            st = {"added": C_ADD, "deleted": C_DEL, "modified": C_NOTE}.get(f["status"], 0)
            A(f"{f['status']}   +{f['additions']}  −{f['deletions']}   "
              f"{len(f['hunks'])} hunk(s)", st)
            A()
            if f.get("blurb"):
                for ln in _wrap(f["blurb"], self.notes_w):
                    A(ln, C_REF if f.get("section") else C_DIM)
                A()
            if not f["hunks"]:
                A("(no textual hunks — mode/binary/rename)", C_DIM)
            else:
                A("HUNKS  →  (n/p to cycle, opens in the file pane)", C_HEAD, curses.A_BOLD)
                for i, hnk in enumerate(f["hunks"]):
                    mark = "▸ " if i == self.cur_target else "  "
                    at = curses.A_BOLD if i == self.cur_target else 0
                    A(f"{mark}✎ hunk {i+1} @ line {hnk.get('line',1)}"[: self.notes_w], 0, at)
        elif e["kind"] == "section":
            s = e["section"]
            for ln in _wrap(s.get("summary", ""), self.notes_w):
                A(ln, 0, curses.A_BOLD)
            A()
            if s.get("narrative"):
                A("WHAT'S GOING ON", C_HEAD, curses.A_BOLD)
                for ln in _wrap(s["narrative"], self.notes_w):
                    A("  " + ln)
                A()
            if s.get("judgment"):
                A("WORTH A LOOK", C_HEAD, curses.A_BOLD)
                for q in s["judgment"]:
                    wrapped = _wrap(q, self.notes_w - 2)
                    for j, ln in enumerate(wrapped):
                        A(("? " if j == 0 else "  ") + ln, C_NOTE)
                A()
            targets = self._targets(s)
            if targets:
                A("OPEN ON THE SIDE  →  (n/p to cycle)", C_HEAD, curses.A_BOLD)
                for i, t in enumerate(targets):
                    mark = "▸ " if i == self.cur_target else "  "
                    icon = "✎" if t["kind"] == "change" else "↪"
                    col = C_REF if t["kind"] == "ref" else 0
                    at = curses.A_BOLD if i == self.cur_target else 0
                    A(f"{mark}{icon} {t['label']}"[: self.notes_w], col, at)
                A()
        return L

    def _read_file(self, path):
        if path in self._file_cache:
            return self._file_cache[path]
        full = os.path.join(self.repo, path) if self.repo else path
        try:
            with open(full, encoding="utf-8", errors="replace") as f:
                data = f.read().splitlines()
        except OSError:
            data = None
        self._file_cache[path] = data
        return data

    def _find_anchor(self, lines, anchor):
        if not anchor or not lines:
            return None
        for i, ln in enumerate(lines):
            if anchor in ln:
                return i
        # loose match: strip whitespace
        a = anchor.strip()
        for i, ln in enumerate(lines):
            if a and a in ln.strip():
                return i
        return None

    def _load_file(self):
        targets = self._cur_targets()
        self.filep.title = "FILE"
        if not targets:
            self.filep.set([("", 0, 0),
                            ("  no change selected — pick a section", C_DIM, 0)])
            return
        t = targets[self.cur_target]
        L = []
        A = lambda text="", c=0, at=0: L.append((text, c, at))
        # what changed (the diff/snippet), colored
        head = t["label"]
        A(("✎ " if t["kind"] == "change" else "↪ ") + head, C_HEAD, curses.A_BOLD)
        if t.get("note"):
            for ln in _wrap(t["note"], self.file_w - 2):
                A("  " + ln, C_NOTE if t["kind"] == "change" else C_REF)
        A()
        for ln in str(t.get("body", "")).splitlines():
            A(ln[: self.file_w - 1], _color_diff_line(ln))
        # the live file
        path = t.get("path")
        lines = self._read_file(path) if path else None
        A()
        if lines is None:
            A("─ live file unavailable "
              + (f"({path})" if path else "(no path recorded)") + " ─", C_DIM)
            self.filep.set(L)
            return
        if t.get("line"):
            anchor_i = max(0, min(len(lines) - 1, int(t["line"]) - 1))
        else:
            anchor_i = self._find_anchor(lines, t.get("anchor"))
        self.filep.title = f"FILE  {path}" + (f":{anchor_i+1}" if anchor_i is not None else "")
        A(f"─ {path} ─", C_DIM)
        start = max(0, (anchor_i - 6)) if anchor_i is not None else 0
        end = min(len(lines), (anchor_i + 40) if anchor_i is not None else 60)
        numw = len(str(end))
        for i in range(start, end):
            gutter = str(i + 1).rjust(numw)
            is_anchor = (anchor_i is not None and i == anchor_i)
            body = lines[i][: self.file_w - numw - 2]
            L.append((f"{gutter} │ {body}", C_LNUM if not is_anchor else C_NOTE,
                      curses.A_BOLD | curses.A_REVERSE if is_anchor else 0))
        # remember where the file view starts so we can auto-scroll to anchor
        self.filep.set(L)
        if anchor_i is not None:
            # position anchor near top third
            header = 0
            for j, (txt, _c, _a) in enumerate(L):
                if txt.startswith(f"{str(anchor_i+1).rjust(numw)} │"):
                    header = j
                    break
            self.filep.off = max(0, header - 4)

    # ---- layout & focus ------------------------------------------------
    def _layout(self, W, H):
        # returns list of (name, x, w) for visible panes, and body height
        sidebar = min(30, max(20, W // 5))
        rest = W - sidebar - 2
        if W >= 100 and rest >= 60:
            notes_w = max(34, rest * 42 // 100)
            file_w = rest - notes_w
            cols = [("list", 0, sidebar),
                    ("notes", sidebar + 1, notes_w),
                    ("file", sidebar + 2 + notes_w, file_w)]
        else:
            main = W - sidebar - 1
            which = "file" if self._two_col_file else "notes"
            cols = [("list", 0, sidebar), (which, sidebar + 1, main)]
        return cols

    def _visible_names(self, cols):
        return [c[0] for c in cols]

    def run(self, scr):
        curses.curs_set(0)
        scr.keypad(True)
        self._init_colors()
        self._two_col_file = False
        # provisional widths for first content build
        self.notes_w, self.file_w = 44, 60
        self._load_entry()
        while True:
            H, W = scr.getmaxyx()
            body_h = H - 2
            cols = self._layout(W, H)
            names = self._visible_names(cols)
            # keep widths fresh for wrapping
            for name, x, w in cols:
                if name == "notes":
                    self.notes_w = w
                if name == "file":
                    self.file_w = w
            # rebuild wrapped content if width changed materially
            self._relayout_content()
            scr.erase()
            self._draw_header(scr, W)
            focusable = [n for n in names]
            self.focus = max(0, min(self.focus, len(focusable) - 1))
            focus_name = focusable[self.focus]
            for name, x, w in cols:
                pane = {"list": self.list, "notes": self.notes, "file": self.filep}[name]
                pane.clamp(body_h)
                pane.draw(scr, 1, x, w, body_h, focused=(name == focus_name))
                # vertical divider
                if x > 0:
                    for yy in range(1, 1 + body_h):
                        try:
                            scr.addch(yy, x - 1, curses.ACS_VLINE, curses.color_pair(C_DIM))
                        except curses.error:
                            pass
            self._draw_footer(scr, W, H, focus_name)
            scr.refresh()

            ch = scr.getch()
            if not self._handle(ch, focus_name, body_h, names):
                break

    def _relayout_content(self):
        # cheap: re-wrap current entry notes+file to current widths
        e = self._cur_entry()
        self.notes.lines = self._notes_lines(e)
        self.notes.clamp(9999)
        # file already sized on load; rebuild to respect new width
        self._rebuild_file_keep_off()

    def _rebuild_file_keep_off(self):
        off = self.filep.off
        self._load_file()
        self.filep.off = off

    def _handle(self, ch, focus_name, body_h, names):
        pane = {"list": self.list, "notes": self.notes, "file": self.filep}[focus_name]
        self.msg = ""
        if ch in (ord("q"), ord("Q")):
            return False
        elif ch == ord("?"):
            self._help()
        elif ch in (ord("l"), curses.KEY_RIGHT, 9):   # 9 = Tab
            self.focus = min(len(names) - 1, self.focus + 1)
        elif ch in (ord("h"), curses.KEY_LEFT, curses.KEY_BTAB):
            self.focus = max(0, self.focus - 1)
        elif ch in (ord("j"), curses.KEY_DOWN):
            if focus_name == "list":
                self.list.move(1, body_h)
                self._load_entry()
            else:
                pane.scroll(1, body_h)
        elif ch in (ord("k"), curses.KEY_UP):
            if focus_name == "list":
                self.list.move(-1, body_h)
                self._load_entry()
            else:
                pane.scroll(-1, body_h)
        elif ch == 4:    # ctrl-d
            if focus_name == "list":
                self.list.move(body_h // 2, body_h); self._load_entry()
            else:
                pane.scroll(body_h // 2, body_h)
        elif ch == 21:   # ctrl-u
            if focus_name == "list":
                self.list.move(-body_h // 2, body_h); self._load_entry()
            else:
                pane.scroll(-body_h // 2, body_h)
        elif ch == ord("g"):
            if focus_name == "list":
                self.list.sel = 0; self.list.off = 0; self._load_entry()
            else:
                pane.to("top", body_h)
        elif ch == ord("G"):
            if focus_name == "list":
                self.list.sel = len(self.list.items) - 1; self._load_entry()
            else:
                pane.to("bot", body_h)
        elif ch in (ord("n"), ord("]")):
            self._cycle_target(1, names)
        elif ch in (ord("p"), ord("[")):
            self._cycle_target(-1, names)
        elif ch == ord("e"):
            self._open_editor()
        elif ch in (10, 13, curses.KEY_ENTER):
            if focus_name == "list" and "notes" in names:
                self.focus = names.index("notes")
        return True

    def _cycle_target(self, d, names):
        targets = self._cur_targets()
        if not targets:
            return
        self.cur_target = (self.cur_target + d) % len(targets)
        e = self._cur_entry()
        self.notes.lines = self._notes_lines(e)   # refresh highlight
        self._load_file()
        if "file" in names:
            self.focus = names.index("file")
        elif "notes" in names:  # 2-col: flip main to file
            self._two_col_file = True

    def _open_editor(self):
        targets = self._cur_targets()
        if not targets:
            self.msg = "no file to open here"
            return
        t = targets[self.cur_target]
        path = t.get("path")
        if not path:
            self.msg = "no path recorded for this change"
            return
        full = os.path.join(self.repo, path) if self.repo else path
        lines = self._read_file(path)
        if t.get("line"):
            line = int(t["line"])
        else:
            line = (self._find_anchor(lines, t.get("anchor")) or 0) + 1 if lines else 1
        editor = os.environ.get("VISUAL") or os.environ.get("EDITOR") or "code"
        base = os.path.basename(editor).split()[0]
        try:
            if base in ("code", "cursor", "codium", "code-insiders"):
                subprocess.Popen([editor, "-g", f"{full}:{line}"])
                self.msg = f"opened {os.path.basename(path)}:{line} in {base}"
            elif base in TERM_EDITORS:
                curses.def_prog_mode(); curses.endwin()
                subprocess.run([editor, f"+{line}", full])
                curses.reset_prog_mode()
            else:
                subprocess.Popen([editor, full])
                self.msg = f"opened {os.path.basename(path)} in {base}"
        except Exception as ex:  # noqa: BLE001
            self.msg = f"editor failed: {ex}"

    # ---- chrome --------------------------------------------------------
    def _init_colors(self):
        curses.start_color()
        curses.use_default_colors()
        defs = {C_HEAD: curses.COLOR_CYAN, C_ADD: curses.COLOR_GREEN,
                C_DEL: curses.COLOR_RED, C_NOTE: curses.COLOR_YELLOW,
                C_REF: curses.COLOR_BLUE, C_DIM: 8, C_MAG: curses.COLOR_MAGENTA,
                C_LNUM: 8, C_SEL: curses.COLOR_WHITE, C_TITLE: curses.COLOR_CYAN}
        for pair, fg in defs.items():
            try:
                curses.init_pair(pair, fg, -1)
            except curses.error:
                curses.init_pair(pair, curses.COLOR_WHITE, -1)

    def _draw_header(self, scr, W):
        pr = self.r.get("pr", {})
        title = f" PR #{pr.get('number','?')}  {pr.get('title','')}"
        try:
            scr.addstr(0, 0, title[:W].ljust(W),
                       curses.color_pair(C_TITLE) | curses.A_BOLD | curses.A_REVERSE)
        except curses.error:
            pass

    def _draw_footer(self, scr, W, H, focus_name):
        keys = "j/k move  h/l focus  n/p change  e edit  ? help  q quit"
        left = self.msg or keys
        right = f"[{focus_name}] "
        s = (" " + left).ljust(W - len(right)) + right
        try:
            scr.addstr(H - 1, 0, s[:W], curses.color_pair(C_DIM) | curses.A_REVERSE)
        except curses.error:
            pass

    def _help(self):
        lines = [
            "  review-pr  —  keys",
            "",
            "  j / k        down / up (list: move section)",
            "  h / l        focus left / right pane",
            "  Tab          cycle focus",
            "  n / p  ] [   next / prev change (opens it on the side)",
            "  g / G        top / bottom",
            "  Ctrl-d / -u  half page",
            "  e            open current file in $EDITOR at the line",
            "  ?            this help          q  quit",
            "",
            "  the right pane is the REAL file from the checked-out PR,",
            "  opened at the changed line. move sections and it follows.",
            "",
            "  press any key to close",
        ]
        H, W = curses.LINES, curses.COLS
        h, w = len(lines) + 2, max(len(x) for x in lines) + 4
        y0, x0 = max(0, (H - h) // 2), max(0, (W - w) // 2)
        win = curses.newwin(h, w, y0, x0)
        win.box()
        for i, ln in enumerate(lines):
            try:
                win.addstr(i + 1, 2, ln[: w - 4],
                           curses.A_BOLD if ln.strip().startswith("review-pr") else 0)
            except curses.error:
                pass
        win.refresh()
        win.getch()


def main():
    args = [a for a in sys.argv[1:]]
    repo = None
    if "--repo" in args:
        i = args.index("--repo")
        repo = args[i + 1]
        del args[i:i + 2]
    path = args[0] if args else (os.environ.get("REVIEW_JSON") or "review.json")
    if not os.path.exists(path):
        print(f"review file not found: {path}")
        sys.exit(1)
    with open(path) as f:
        review = json.load(f)
    repo = repo or review.get("repo_root") or ""
    if repo and not os.path.isdir(repo):
        print(f"warning: repo_root {repo!r} not found; live file view disabled")
        repo = ""
    curses.wrapper(lambda scr: App(review, repo).run(scr))


if __name__ == "__main__":
    main()
