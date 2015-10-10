" vim:fdm=marker
"
" Location: ftplugin/python/folding.vim
" Author: Pascal Lalancette (okcompute@icloud.com)


" Patterns {{{
let s:def_regex =  '^\s*\%(class\|def\) \w\+'
let s:blank_regex = '^\s*$'
let s:decorator_regex = '^\s*@'
" }}}

" Handles multibyte character {{{
let s:symbol = matchstr(&fillchars, 'fold:\zs.')
if s:symbol == ''
    let s:symbol = ' '
endif
" }}}

" folding 'text' function. Defines what text will be displayed on the folded
" line. {{{
function! g:python_folding_text()
    let fs = v:foldstart
    while getline(fs) !~ s:def_regex
        let fs = nextnonblank(fs + 1)
    endwhile
    let line = getline(fs)

    let has_numbers = &number || &relativenumber
    let nucolwidth = &fdc + has_numbers * &numberwidth
    let windowwidth = winwidth(0) - nucolwidth - 6
    let foldedlinecount = v:foldend - v:foldstart

    " expand tabs into spaces
    let onetab = strpart('          ', 0, &tabstop)
    let line = substitute(line, '\t', onetab, 'g')

    let line = strpart(line, 0, windowwidth - 2 -len(foldedlinecount))
    let line = substitute(line, '\%("""\|''''''\)', '', '')
    let fillcharcount = windowwidth - len(line) - len(foldedlinecount) + 1
    return line . ' ' . repeat(s:symbol, fillcharcount) . ' ' . foldedlinecount
endfunction
"}}}

" Folding 'expr' method. This defines how to fold inside the file. {{{
function! g:python_folding_expr(lnum)

    let line = getline(a:lnum)
    let indent = indent(a:lnum)
    let prev_line = getline(a:lnum - 1)

    if line =~ s:decorator_regex
        return ">".(indent / &shiftwidth + 1)
    endif

    if line =~ s:def_regex
        " single line def
        if indent(a:lnum) >= indent(a:lnum+1)
            return '='
        endif
        " Check if last decorator is before the last def
        let decorated = 0
        let lnum = a:lnum - 1
        while lnum > 0
            if getline(lnum) =~ s:def_regex
                break
            elseif getline(lnum) =~ s:decorator_regex
                let decorated = 1
                break
            endif
            let lnum -= 1
        endwhile
        if decorated
            return '='
        else
            return ">".(indent / &shiftwidth + 1)
        endif
    endif

    if line =~ s:blank_regex
        if prev_line =~ s:blank_regex
            if indent(a:lnum + 1) == 0 && getline(a:lnum + 1) !~ s:blank_regex
                return 0
            endif
            return -1
        else
            return '='
        endif
    endif

    return '='

endfunction
"}}}

function! s:set_folding() "{{{
    setlocal foldmethod=expr
    setlocal foldexpr=g:python_folding_expr(v:lnum)
    setlocal foldtext=g:python_folding_text()
endfunction "}}}

autocmd BufEnter *.py call s:set_folding()
