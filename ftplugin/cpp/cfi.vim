" vim:foldmethod=marker:fen:
scriptencoding utf-8


if get(g:, 'cfi_disable') || get(g:, 'loaded_cfi_ftplugin_cpp')
    finish
endif
let g:loaded_cfi_ftplugin_cpp = 1

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" let s:FUNCTION_PATTERN = '\C'.'\(\w\+::\)*\(\w\+\)\s*('
" 自社特別仕様
let s:FUNCTION_LINE_PATTERN = '\v^[^ _#/].*(\w+::)*(\w+)\s*\('
let s:FUNCTION_PATTERN = '\v(\w+::)*(\w+)\s*\('

let s:finder = cfi#create_finder('cpp')

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
            " 関数のような形式になっている箇所を後方に探して移動
            if search(s:FUNCTION_LINE_PATTERN, 'bW') == 0
                return NONE
            endif
            " 検索パターンを絶対的に信用して、残りのチェックは全部削除
            let funcname = matchlist(getline('.'), s:FUNCTION_PATTERN)
            " 末尾の ( を取り除く
            let self.temp.funcname = get(funcname, 0, '')[:-2]
            break
        endwhile
    finally
        let &vb = vb
    endtry

    " 多分関数開始位置を探す、見つからなかったらだめ
    if search('{') == 0
        return NONE
    endif
    " なんかよく分かんないけど、最初'{'の位置にいたらだめ
    " if line('.') == orig_lnum && col('.') == orig_col
    "     return NONE
    " endif
    " 関数開始位置を返す
    return [line('.'), col('.')]
endfunction "}}}

function! s:finder.find_end() "{{{
    let NONE = []
    let [orig_lnum, orig_col] = [line('.'), col('.')]

    let vb = &vb
    setlocal vb t_vb=
    " 終わりの位置に飛ぶ
    keepjumps normal! ][
    let &vb = vb

    " ここに来た時点でfind_beginを通っていて、現在地は関数先頭の'{'にいる
    " そこから変わっていなければだめ
    if line('.') == orig_lnum && col('.') == orig_col
        return NONE
    endif
    " 今いる位置が'}'でなければbad
    if getline('.')[col('.')-1] !=# '}'
        return NONE
    endif
    let self.is_ready = 1
    " 関数終了位置を返す
    return [line('.'), col('.')]
endfunction "}}}

call cfi#register_finder('cpp', s:finder)
unlet s:finder



let &cpo = s:save_cpo
