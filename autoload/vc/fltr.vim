" ============================================================================
" File:         autoload/vc/fltr.vim
" Description:  Filter/Fuzzy search
" Author:       Juneed Ahamed
" Credits:      Method pyMatch copied and modified from : Alexey Shevchenko
"               Userid FelikZ/ctrlp-py-matcher from github
" =============================================================================

"filter contents / fuzzy search for {{{1
"vars {{{2
let s:rez = []
let b:flines = []
let [b:slst, s:fregex]  = ["", ""]
"2}}}

"Filters and returns filteredlines and regex used to match {{{2
fun! vc#fltr#filter(items, str, limit)
    let b:flines = []
    let s:fregex = ""
    call s:doFilter(a:items, a:str, a:limit)
    retu [b:flines, s:fregex]
endf
"2}}}

"filters contents using any of the following in mentioned order {{{2
"python fuzzy | vim fuzzy | vim no fuzzy 
fun! s:doFilter(items, str, limit)
    let ignchars = "[\\+\\*\\\\~\\@\\%\\(\\)\\[\\]\\{\\}\\']"
    let str = substitute(a:str, ignchars, "", "g")
    let str = substitute(str, "\\.\\+", "", "g")
    if str == '' | let b:flines=a:items | retu | en
    
    let dummy = substitute(str, "[\\\"\\&]", "", "g")
    if dummy == '' | let b:flines=a:items | retu | en

    if (g:vc_fuzzy_search == 1)
        if has('python') 
            call s:pyMatch(a:items, str, a:limit)
            if len(s:rez) > 0
                let b:flines = s:rez[ : g:vc_max_buf_lines]
                unlet! s:rez
                let s:rez = []
            else
                "for older vim versions not supporting bind
                let b:flines = split(b:slst, "\n")
                let b:flines = b:flines[ : g:vc_max_buf_lines]
                unlet! b:slst
            endif
        else
            try | call s:vimMatch(a:items, str, a:limit) 
            catch | call s:vimMatch_old(a:items, str, a:limit) | endt
        endif
    else
        call s:vimMatch_old(a:items, str, a:limit)
    endif
endf
"2}}}

"python fuzzy filter {{{2
fun! s:pyMatch(items, str, limit)
python << EOF
import vim, re
import traceback
vim.command("let b:slst = ''")
items = vim.eval('a:items')
astr = vim.eval('a:str')
lowAstr = astr.lower()
limit = int(vim.eval('a:limit'))
hasbind = True
try:
    #Oops supported after 7.3+ or something
    rez = vim.bindeval('s:rez')
except:
    hasbind = False
    pass

def create_plain_regex(lowAstr):
    regex, fregex = "", ""
    if lowAstr:
        for c in lowAstr[:-1]:
            regex += c + '[^' + c + ']*?'
            fregex += c + '[^' + c + ']*'
        else:
            regex += lowAstr[-1]
            fregex += lowAstr[-1]
    return regex, fregex

try:
    regex, fregex = "", "" 
    removequotes = lambda x : x.replace("\"", "")
    splits = [split for split in lowAstr.split('&') if split]

    for split in map(removequotes, splits[:-1]):
        regex += "(" + split + ").*"
        fregex += "(" + split + ").*"
    else:
        split = splits[-1]
        if split.startswith("\"") or split.endswith("\"") or "&" == lowAstr[-1]:
            split = removequotes(split)
            regex += "(" + split + ")"
            fregex += "(" + split + ")"
        else:
            split = removequotes(split)
            _regex, _fregex = create_plain_regex(split)
            regex += _regex
            fregex += _fregex
except:
    pass

try:
    matches = []
    res = []
    prog = re.compile(regex)
    for line in items:
        lowline = line.lower()
        result = prog.findall(lowline)
        if result:
            result = result[-1]
            if type(result) == type(()):
                result = result[-1]
            mstart = lowline.rfind(result)
            mend = mstart + len(result)
            mlen = mend - mstart
            score = len(line) * (mlen)
            res.append((score, line, result))

    sortedlist = sorted(res, key=lambda x: x[0], reverse=False)[:limit]
    sortedlines = [x[1] for x in sortedlist]

    try:
        if not hasbind:
            result = "\n".join(sortedlines) 
            p = re.compile('\'|\"')
            result = p.sub("", result)
            vim.command("let b:slst = \'%s\'" % result)
        else:
            rez.extend(sortedlines)

        vim.command("let s:fregex = \'%s\'" % fregex)
    except:
        pass
except:
    pass

del sortedlist
del sortedlines
del res
del result
del items
EOF
endf
"2}}}

"vim fuzzy filter {{{2
fun! s:vimMatch(clines, fltr, limit)
    let s:fregex = ""
    let ranked = {}
    for idx in range(0, len(a:fltr)-2)
        let s:fregex = s:fregex . a:fltr[idx]  . '[^'  . a:fltr[idx]  . ']*'
    endfor
    let s:fregex = s:fregex . a:fltr[len(a:fltr)-1]
    let s:fregex = '\v\c'.s:fregex
    for line in a:clines
        let matched = matchstr(line, s:fregex)
        if len(matched)
            let mstart = match(line, s:fregex)
            let mend = mstart + len(matched)
            let score = len(line) * (mend - mstart + 1)
            let rlines = get(ranked, score, [])
            call add(rlines, line)
            let ranked[score] = rlines
        endif
    endfor
    let b:flines = []
    for key in sort(keys(ranked), 'vc#utils#sortconvint')
        call extend(b:flines, ranked[key])
    endfor
    let b:flines = b:flines[:a:limit]
    unlet! ranked
endf
"2}}}

"vim filter no fuzzy {{{2
fun! s:vimMatch_old(clines, fltr, limit)
    let b:flines = filter(copy(a:clines),
                \ 'strlen(a:fltr) > 0 ? stridx(v:val, a:fltr) >= 0 : 1')
    let b:flines = b:flines[ : g:vc_max_buf_lines]
    let s:fregex = a:fltr
endf
"2}}}
"1}}}
