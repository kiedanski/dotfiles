set shiftwidth=4
set tabstop=4
set softtabstop=4
set expandtab
set autoindent
set smartindent
set colorcolumn=80
setlocal path=.,**

if executable("flake8")
  " compiler flake8
  set makeprg=flake8\ %:S
  setlocal errorformat=%f:%l:%c:\ %t%n\ %m
endif

setlocal include=^\\s*\\(from\\\|import\\)\\s*\\zs\\(\\S\\+\\s\\{-}\\)*\\ze\\($\\\|\ as\\\|\ import\\)
setlocal define=^\\s*\\<\\(def\\\|class\\)\\>

function! PyInclude(fname)
  let parts = split(a:fname, ' import ')
  let l = parts[0]
  if len(parts) > 1
	let r = parts[1]
	let joined = join([l, r]. '.')
	let fp = substitute(joined, '\.', '/', 'g') . '.py'
	let found = glob(fp, 1)
	if len(found)
	  return found
	endif
  endif
  return substitute(l, '\.', '/', 'g') . '.py'
endfunction
setlocal includeexpr=PyInclude(v:fname)

nnoremap <leader>a :argadd <c-r>=fnameescape(expand('%:p:h'))<cr>/**/*.py<C-d>
