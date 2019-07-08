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


let s:FUNCTION_PATTERN = '\C'.'\(\w\+::\)*\(\w\+\)\s*('

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
            if search(s:FUNCTION_PATTERN, 'bW') == 0
                return NONE
            endif
            " Function name when filetype=c has nothing about syntax info.
            " (without this condition, if-statement is recognized as function)
            " 自作関数なのかそうでないのかをsynstackを使って判断しているようだ
            " 試して見ると確かに自作？関数では空が返ってくる
            " よく分からん、単に名前だけで判断しているわけではない
            if !empty(synstack(line('.'), col('.')))
                continue
            endif
            " 関数名を取得
            let funcname = matchlist(getline('.'), s:FUNCTION_PATTERN)
            let funcname = get(funcname, 1, '') .. get(funcname, 2, '')
            if funcname ==# ''
                return NONE
            endif
            " ここは何をやっているのか。。。
            " ああ、searchとsearchpairを呼んでいるだけか
            " 関数名(引数)の終わりに移動しているっぽい
            for [fn; args] in [
            \   ['search', '(', 'W'],
            \   ['searchpair', '(', '', ')'],
            \]
                if call(fn, args) == 0
                    return NONE
                endif
            endfor
            " ここもよく分からないけれど、ここに来れば確定
            " 後ろをすべて連結している、[数字 :]は数字以降すべて
            " 関数の宣言部を除外しているのかな
            if join(getline('.', '$'), '')[col('.') :] =~# '^\s*;'
                return NONE
            else
                let self.temp.funcname = funcname
                break
            endif
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
