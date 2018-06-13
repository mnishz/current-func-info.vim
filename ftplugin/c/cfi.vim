" vim:foldmethod=marker:fen:
scriptencoding utf-8


if get(g:, 'cfi_disable') || get(g:, 'loaded_cfi_ftplugin_c')
    finish
endif
let g:loaded_cfi_ftplugin_c = 1

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


let s:FUNCTION_PATTERN = '\C'.'\(\w\+\)\s*('

let s:finder = cfi#create_finder('c')

function! s:finder.get_func_name() "{{{
    let NONE = ''
    if self.phase isnot 2 || !has_key(self.temp, 'funcname')
        return NONE
    endif
    return self.temp.funcname
endfunction "}}}

function! s:finder.find_begin() "{{{
    let NONE = []
    let [orig_lnum, orig_col] = [line('.'), col('.')]

    let vb = &vb
    setlocal vb t_vb=
    try
        " Jump to function-like word, and check arguments, and block.
        while 1
            " �֐��̂悤�Ȍ`���ɂȂ��Ă���ӏ�������ɒT���Ĉړ�
            if search(s:FUNCTION_PATTERN, 'bW') == 0
                return NONE
            endif
            " Function name when filetype=c has nothing about syntax info.
            " (without this condition, if-statement is recognized as function)
            " ����֐��Ȃ̂������łȂ��̂���synstack���g���Ĕ��f���Ă���悤��
            " �����Č���Ɗm���Ɏ���H�֐��ł͋󂪕Ԃ��Ă���
            " �悭�������A�P�ɖ��O�����Ŕ��f���Ă���킯�ł͂Ȃ�
            if !empty(synstack(line('.'), col('.')))
                continue
            endif
            " �֐������擾
            let funcname = get(matchlist(getline('.'), s:FUNCTION_PATTERN), 1, '')
            if funcname ==# ''
                return NONE
            endif
            " �����͉�������Ă���̂��B�B�B
            " �����Asearch��searchpair���Ă�ł��邾����
            " �֐���(����)�̏I���Ɉړ����Ă�����ۂ�
            for [fn; args] in [
            \   ['search', '(', 'W'],
            \   ['searchpair', '(', '', ')'],
            \]
                if call(fn, args) == 0
                    return NONE
                endif
            endfor
            " �������悭������Ȃ�����ǁA�����ɗ���Ίm��
            " �������ׂĘA�����Ă���A[���� :]�͐����ȍ~���ׂ�
            " �֐��̐錾�������O���Ă���̂���
            if join(getline('.', '$'), '')[col('.') :] =~# '\s*[^;]'
                let self.temp.funcname = funcname
                break
            endif
        endwhile
    finally
        let &vb = vb
    endtry

    " �����֐��J�n�ʒu��T���A������Ȃ������炾��
    if search('{') == 0
        return NONE
    endif
    " �Ȃ񂩂悭������Ȃ����ǁA�ŏ�'{'�̈ʒu�ɂ����炾��
    " if line('.') == orig_lnum && col('.') == orig_col
    "     return NONE
    " endif
    " �֐��J�n�ʒu��Ԃ�
    return [line('.'), col('.')]
endfunction "}}}

function! s:finder.find_end() "{{{
    let NONE = []
    let [orig_lnum, orig_col] = [line('.'), col('.')]

    let vb = &vb
    setlocal vb t_vb=
    " �I���̈ʒu�ɔ��
    keepjumps normal! ][
    let &vb = vb

    " �����ɗ������_��find_begin��ʂ��Ă��āA���ݒn�͊֐��擪��'{'�ɂ���
    " ��������ς���Ă��Ȃ���΂���
    if line('.') == orig_lnum && col('.') == orig_col
        return NONE
    endif
    " ������ʒu��'}'�łȂ����bad
    if getline('.')[col('.')-1] !=# '}'
        return NONE
    endif
    let self.is_ready = 1
    " �֐��I���ʒu��Ԃ�
    return [line('.'), col('.')]
endfunction "}}}

call cfi#register_finder('c', s:finder)
unlet s:finder



let &cpo = s:save_cpo
