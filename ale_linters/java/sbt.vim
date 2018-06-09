" Author: ivangreene <ivan@ivan.sh>
" Description: Lints java files using sbt

call ale#Set('java_sbt_executable', 'sbt')
call ale#Set('java_sbt_options', '')

function! ale_linters#java#sbt#GetExecutable(buffer) abort
    return ale#Var(a:buffer, 'java_sbt_executable')
endfunction

function! ale_linters#java#sbt#GetCommand(buffer) abort
    let l:executable = ale_linters#java#sbt#GetExecutable(a:buffer)

    return ale#path#BufferCdString(system('git rev-parse --show-cdup 2>/dev/null'))
    \ . ale#Escape(l:executable)
    \ . ' -Dsbt.log.noformat=true'
    \ . ' ' . ale#Var(a:buffer, 'java_sbt_options')
    \ . ' compile'
endfunction

function! ale_linters#java#sbt#Handle(buffer, lines) abort
    let l:directory = expand('#' . a:buffer . ':p:h')
    let l:pattern = '\v^\[([^\[\]]*)\] *(.+):(\d+): *(.*)$'
    let l:symbol_pattern = '\v^\[[^\[\]]*\] +(symbol): *(class|method|variable) +([^ ]+)$'
    let l:directive_pattern = '\v^\[[^\[\]]*\] +([a-zA-Z]+): (.+)$'
    let l:output = []

    for l:match in ale#util#GetMatches(a:lines, [l:pattern, l:symbol_pattern, l:directive_pattern])
        if empty(l:match[3])
          let l:output[-1].text .= ' ' . l:match[1] . ': ' . l:match[2]
        elseif empty(l:match[4])
            " Add symbols to 'cannot find symbol' errors.
            if l:output[-1].text is# 'error: cannot find symbol'
                let l:output[-1].text .= ': ' . l:match[3]
            endif
        else
            call add(l:output, {
            \   'filename': l:match[2],
            \   'lnum': l:match[3] + 0,
            \   'text': l:match[1] . ': ' . l:match[4],
            \   'type': l:match[1] is# 'error' ? 'E' : 'W',
            \   'col': 0,
            \})
        endif
    endfor

    return l:output
endfunction

call ale#linter#Define('java', {
\   'name': 'sbt',
\   'executable_callback': 'ale_linters#java#sbt#GetExecutable',
\   'command_chain': [
\       {'callback': 'ale_linters#java#sbt#GetCommand', 'output_stream': 'stdout'},
\   ],
\   'callback': 'ale_linters#java#sbt#Handle',
\})
