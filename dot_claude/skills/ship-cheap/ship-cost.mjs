#!/usr/bin/env node
// ship-cost.mjs — exact $ cost of a /ship or /ship-cheap run, from local transcripts. Zero deps.
//
// A run's cost = the MAIN session transcript (<project>/<sessionId>.jsonl) PLUS every SUBAGENT
// transcript (<project>/<sessionId>/subagents/agent-*.jsonl). Subagent files can be split across
// multiple project dirs when a worktree forks the project slug, but they share the session id as
// their subdir name — so we scan every project dir for that id.
//
// Usage:
//   node ship-cost.mjs --session <sessionId>                       # whole session (main + all subagents)
//   node ship-cost.mjs --session <id> --since <ISO> --until <ISO>  # scope one run inside a shared session
//   node ship-cost.mjs --state .omc/state/ship-cheap-<slug>.json   # read sessionId + per-stage windows
//   node ship-cost.mjs                                             # most-recently-modified session
//   node ship-cost.mjs --json
//
// Prices are $ per 1e6 tokens; edit PRICES to add providers/models. Unknown models are flagged (priced 0).

import fs from 'fs';
import os from 'os';
import path from 'path';

const PRICES = {
  'claude-opus-4-8':           { in: 5.00, cw: 6.25, cr: 0.50, out: 25.00 },
  'claude-sonnet-4-6':         { in: 3.00, cw: 3.75, cr: 0.30, out: 15.00 },
  'claude-haiku-4-5-20251001': { in: 1.00, cw: 1.25, cr: 0.10, out: 5.00 },
};
const ZERO = { in: 0, cw: 0, cr: 0, out: 0 };
const PROJECTS = path.join(os.homedir(), '.claude', 'projects');

function parseArgs() {
  const a = process.argv.slice(2), o = { json: false };
  for (let i = 0; i < a.length; i++) {
    const k = a[i];
    if (k === '--session') o.session = a[++i];
    else if (k === '--since') o.since = a[++i];
    else if (k === '--until') o.until = a[++i];
    else if (k === '--state') o.state = a[++i];
    else if (k === '--json') o.json = true;
  }
  return o;
}

const projectDirs = () =>
  fs.existsSync(PROJECTS)
    ? fs.readdirSync(PROJECTS).map(d => path.join(PROJECTS, d)).filter(p => { try { return fs.statSync(p).isDirectory(); } catch { return false; } })
    : [];

function findTranscripts(sessionId) {
  const files = [];
  for (const dir of projectDirs()) {
    const main = path.join(dir, sessionId + '.jsonl');
    if (fs.existsSync(main)) files.push({ file: main, kind: 'main' });
    const sub = path.join(dir, sessionId, 'subagents');
    if (fs.existsSync(sub)) for (const f of fs.readdirSync(sub)) if (f.endsWith('.jsonl')) files.push({ file: path.join(sub, f), kind: 'subagent' });
  }
  return files;
}

function mostRecentSession() {
  let best = null, bestM = 0;
  for (const dir of projectDirs()) {
    for (const f of fs.readdirSync(dir)) {
      if (!f.endsWith('.jsonl')) continue;
      let m; try { m = fs.statSync(path.join(dir, f)).mtimeMs; } catch { continue; }
      if (m > bestM) { bestM = m; best = f.replace(/\.jsonl$/, ''); }
    }
  }
  return best;
}

function windowsFromState(stateFile) {
  const s = JSON.parse(fs.readFileSync(stateFile, 'utf8'));
  let windows = null;
  if (s.stageMarkers) {
    const ents = Object.entries(s.stageMarkers).sort((a, b) => (a[1] < b[1] ? -1 : 1));
    windows = ents.map((e, i) => ({ stage: e[0], from: e[1], to: ents[i + 1] ? ents[i + 1][1] : '9999' }));
  }
  return { sessionId: s.sessionId, windows, since: s.startedAt, until: s.finishedAt };
}

const addBucket = (acc, u, p) => {
  const inp = u.input_tokens || 0, cw = u.cache_creation_input_tokens || 0, cr = u.cache_read_input_tokens || 0, out = u.output_tokens || 0;
  const cost = (inp * p.in + cw * p.cw + cr * p.cr + out * p.out) / 1e6;
  acc.inp += inp; acc.cw += cw; acc.cr += cr; acc.out += out; acc.cost += cost;
  return cost;
};
const newAcc = () => ({ inp: 0, cw: 0, cr: 0, out: 0, cost: 0 });

function main() {
  const o = parseArgs();
  let sessionId = o.session, since = o.since, until = o.until, windows = null;
  if (o.state) { const st = windowsFromState(o.state); sessionId = sessionId || st.sessionId; windows = st.windows; since = since || st.since; until = until || st.until; }
  if (!sessionId) sessionId = mostRecentSession();
  if (!sessionId) { console.error('no session found'); process.exit(1); }

  const files = findTranscripts(sessionId);
  if (!files.length) { console.error('no transcripts for session ' + sessionId); process.exit(1); }

  const total = newAcc(), main_ = newAcc(), sub = newAcc();
  const byModel = {}, byPhase = {}, unknown = new Set();
  const seen = new Set(); // dedupe by message id — transcripts repeat each message ~3× (history rewrites)
  if (windows) for (const w of windows) byPhase[w.stage] = newAcc();

  for (const { file, kind } of files) {
    for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
      if (!line) continue;
      let r; try { r = JSON.parse(line); } catch { continue; }
      const u = r.message && r.message.usage;
      if (!u) continue;
      const mid = (r.message.id ? r.message.id + '|' + (r.requestId || '') : null);
      if (mid) { if (seen.has(mid)) continue; seen.add(mid); }
      const ts = r.timestamp;
      if (since && ts && ts < since) continue;
      if (until && ts && ts > until) continue;
      const model = (r.message.model) || '?';
      const p = PRICES[model] || ZERO;
      if (!PRICES[model]) unknown.add(model);
      addBucket(total, u, p);
      addBucket(kind === 'main' ? main_ : sub, u, p);
      byModel[model] = byModel[model] || newAcc();
      addBucket(byModel[model], u, p);
      if (windows && ts) for (const w of windows) if (ts >= w.from && ts < w.to) { addBucket(byPhase[w.stage], u, p); break; }
    }
  }

  const result = { sessionId, files: files.length, subagentFiles: files.filter(f => f.kind === 'subagent').length,
    total, main: main_, subagents: sub, byModel, byPhase: windows ? byPhase : null, unknownModels: [...unknown] };

  if (o.json) { console.log(JSON.stringify(result, null, 2)); return; }

  const $ = n => '$' + n.toFixed(2);
  const K = n => (n / 1e6).toFixed(2) + 'M';
  console.log(`\nRun cost — session ${sessionId}`);
  console.log(`  transcripts: 1 main + ${result.subagentFiles} subagent file(s)` + (since || until ? `  [window ${since || '…'} → ${until || '…'}]` : ''));
  console.log('  ' + '-'.repeat(56));
  console.log(`  TOTAL            ${$(total.cost).padStart(9)}`);
  console.log(`    ├ main loop    ${$(main_.cost).padStart(9)}   (${(100 * main_.cost / total.cost || 0).toFixed(0)}%)`);
  console.log(`    └ subagents    ${$(sub.cost).padStart(9)}   (${(100 * sub.cost / total.cost || 0).toFixed(0)}%)`);
  console.log(`  tokens: in ${K(total.inp)} | out ${K(total.out)} | cache-write ${K(total.cw)} | cache-read ${K(total.cr)}`);
  console.log('  by model:');
  for (const [m, a] of Object.entries(byModel).sort((x, y) => y[1].cost - x[1].cost))
    console.log(`    ${m.padEnd(28)} ${$(a.cost).padStart(9)}   out ${K(a.out)}  cr ${K(a.cr)}`);
  if (windows) {
    console.log('  by phase:');
    for (const w of windows) console.log(`    ${w.stage.padEnd(12)} ${$(byPhase[w.stage].cost).padStart(9)}`);
  }
  if (unknown.size) console.log(`  ⚠ unknown models priced $0 (add to PRICES): ${[...unknown].join(', ')}`);
  console.log('');
}

main();
