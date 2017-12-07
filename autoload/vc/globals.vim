" =============================================================================
" File:         autoload/vcglobals.vim
" Description:  Handle all globals
" Author:       Juneed Ahamed
" =============================================================================

"global vars {{{2
"start init {{{3
fun! vc#globals#init()
    try| call s:auth() | catch | endt
    try| call s:custom() | catch | endt
    try| call s:customize() | catch | endt
    try| call s:cache() | catch | endt
    try| call s:signs() | catch | endt
    try| call s:ignores() | catch | endt
    try| call s:fuzzy() | catch | endt
    try| call s:urls() | catch | endt
    try| call s:git() | catch | endt
    try| call s:setkeys() | catch | endt
    
    let g:vc_key_patt = '\v\c\d+:'
    "g:bmarks = { filepath : id }
    let g:bmarks = {}
    let g:bmarkssid = 1000
    let g:vc_info_str = "--INFO--:"
    let [g:vc_menu_start_str, g:vc_menu_end_str ] = [">>>", "<<<"]
    return 1
endf
"3}}}

"auth info {{{3
fun! s:auth()
    let g:vc_username = get(g:, 'vc_username', "") 
    let g:vc_password = get(g:, 'vc_password', "") 
    let g:vc_auth_errno = get(g:, 'vc_auth_errno', "E170001") 
    let g:vc_auth_errmsg = get(g:, 'vc_auth_errmsg', '\cusername\|\cpassword') 
    let g:vc_auth_disable = get(g:, 'vc_auth_disable', 0) 
endf
"3}}}

"custom gvars {{{3
fun! s:custom()
    let g:vc_default_repo = get(g:, 'vc_default_repo', "")
    let g:vc_max_logs = get(g:, 'vc_max_logs', 50)
    let g:vc_max_open_files = get(g:, 'vc_max_open_files', 10)
    let g:vc_max_diff = get(g:, 'vc_max_diff', 2)
    let g:vc_max_buf_lines = get(g:, 'vc_max_buf_lines', 80)
    let g:vc_window_max_size = get(g:, 'vc_window_max_size', 20)
    let g:vc_warn_branch_log = get(g:, 'vc_warn_branch_log', 1)
    let g:vc_enable_debug = get(g:, 'vc_enable_debug', 0)
    let g:vc_enable_extended_debug = get(g:, 'vc_enable_extended_debug', 0)
    let g:vc_browse_max_files_cnt= get(g:, 'vc_browse_max_files_cnt', 10000)
    let g:vc_browse_repo_max_files_cnt= get(g:, 'vc_browse_repo_max_files_cnt', 1000)
    let g:vc_sticky_on_start = get(g:, 'vc_sticky_on_start', 0)
    let g:vc_send_soc_command = get(g:, 'vc_send_soc_command', 1)
    let g:vc_more_msg_len = get(g:, 'vc_more_msg_len', 40)
    let g:vc_log_name = get(g:, 'vc_log_name', '')
    let g:vc_donot_confirm_cmd = get(g:, 'vc_donot_confirm_cmd', 0)
    let g:vc_prompt_args = get(g:, 'vc_prompt_args', 1)
    let g:vc_autocomplete_svnurls = get(g:, 'vc_autocomplete_svnurls', 1)
    let g:vc_commit_allow_blank_lines = get(g:, 'vc_commit_allow_blank_lines', 0)
    let g:vc_enable_buffers = get(g:, 'vc_enable_buffers', 0)
endf
"3}}}

"customize gvars {{{3
fun! s:customize() 
    fun! s:get_hl(varname, defval)
        retu !exists(a:varname) || !hlexists(eval(a:varname)) ? a:defval : eval(a:varname)
    endf

    let g:vc_custom_fuzzy_match_hl = s:get_hl('g:vc_custom_fuzzy_match_hl', 'Directory')
    let g:vc_custom_menu_color = s:get_hl('g:vc_custom_menu_color', 'MoreMsg')
    let g:vc_custom_error_color = s:get_hl('g:vc_custom_error_color', 'Error')
    let g:vc_custom_info_color = s:get_hl('g:vc_custom_info_color', 'Comment')
    let g:vc_custom_binfolistsep_color = s:get_hl('g:vc_custom_binfolistsep_color', 'Error')
    let g:vc_custom_prompt_color = s:get_hl('g:vc_custom_prompt_color', 'Title')
    let g:vc_custom_statusbar_title = s:get_hl('g:vc_custom_statusbar_title', 'LineNr')
    let g:vc_custom_statusbar_title = '%#' . g:vc_custom_statusbar_title .'#'
    let g:vc_custom_statusbar_ops_hl = s:get_hl('g:vc_custom_statusbar_ops_hl', 'Search')
    let g:vc_custom_statusbar_sel_hl = s:get_hl('g:vc_custom_statusbar_sel_hl', 'Question')
    let g:vc_custom_sticky_hl = s:get_hl('g:vc_custom_sticky_hl', 'Function')
    let g:vc_custom_commit_files_hl = s:get_hl('g:vc_custom_commit_files_hl', 'Directory')
    let g:vc_custom_commit_header_hl = s:get_hl('g:vc_custom_commit_header_hl', 'Comment')
    let g:vc_custom_repo_header_hl = s:get_hl('g:vc_custom_repo_header_hl', 'Title')
    let g:vc_custom_op_hl = s:get_hl('g:vc_custom_op_hl', 'Error')

    let g:vc_custom_date_color = s:get_hl('g:vc_custom_date_color', 'Identifier')
    let g:vc_custom_rev_color = s:get_hl('g:vc_custom_rev_color', 'Question')
    let g:vc_custom_st_modified_hl = s:get_hl('g:vc_custom_st_modified_hl', 'PreProc')
    let g:vc_custom_st_na_hl = s:get_hl('g:vc_custom_st_na_hl', 'Error')
endf
"3}}}
    
"cache gvars {{{3
fun! s:cache()
    fun! s:createdir(dirpath)
        if isdirectory(a:dirpath) | retu 1 | en
        if filereadable(a:dirpath) 
            retu s:showerr("Error " . a:dirpath . 
                        \ " already exist as a file expecting a directory")
        endif
        if exists("*mkdir")
            try | call mkdir(a:dirpath, "p")
            catch
                retu s:showerr("Error creating cache dir: " .
                            \ a:dirpath . " " .  v:exception)
            endtry
        endif
        return 1
    endf

    let g:vc_browse_cache_all = get(g:, 'vc_browse_cache_all', 0)
    let g:vc_browse_bookmarks_cache = get(g:, 'vc_browse_bookmarks_cache', 0)
    let g:vc_browse_repo_cache = get(g:, 'vc_browse_repo_cache', 0)
    let g:vc_browse_workingcopy_cache = get(g:, 'vc_browse_workingcopy_cache', 0)
    let g:vc_log_cache = get(g:, 'vc_log_cache', 0)
    let g:vc_browse_cache_max_cnt = get(g:, 'vc_browse_cache_max_cnt', 20)

    let g:vc_cache_dir = get(g:, 'vc_cache_dir',
			    \ !has('win32') ? expand($HOME . "/" . ".cache") : "")

    "Create top dir
    if !s:createdir(g:vc_cache_dir) | let g:vc_cache_dir = "" | en
    let g:vc_cache_dir = isdirectory(g:vc_cache_dir) ? g:vc_cache_dir . "/vc" : ""
    "Create cache dir
    if g:vc_cache_dir != "" && !s:createdir(g:vc_cache_dir) 
        let g:vc_cache_dir = ""
    endif

    let isdir = isdirectory(g:vc_cache_dir)
    let g:vc_browse_repo_cache = isdir && (g:vc_browse_repo_cache || g:vc_browse_cache_all)
    let g:vc_browse_workingcopy_cache = isdir &&
                \ (g:vc_browse_workingcopy_cache || g:vc_browse_cache_all)
    let g:vc_browse_bookmarks_cache = isdir &&
                \ (g:vc_browse_bookmarks_cache || g:vc_browse_cache_all)
    let g:vc_log_cache = isdir && g:vc_log_cache

    let g:vc_logversions = []
endf
"3}}}

"signs gvars {{{3
fun! s:signs()
    if !exists('g:vc_signs') | let g:vc_signs = 1 | en
    if !has('signs') | let g:vc_signs = 0 | en

    if g:vc_signs | sign define vcmark text=s> texthl=Question linehl=Question
    en
    if g:vc_signs | sign define vcbook text=b> texthl=Constant linehl=Constant
    en
endf
"3}}}

"ignore gvars{{{3
fun! s:ignores()
    let ign_files = ['\.bin', '\.zip', '\.bz2', '\.tar', '\.gz', 
                \ '\.egg', '\.pyc', '\.so', '\.git',
                \ '\.png', '\.gif', '\.jpg', '\.ico', '\.bmp', 
                \ '\.psd', '\.pdf']

    if exists('g:vc_ignore_files') && type(g:vc_ignore_files) == type([])
        for ig in g:vc_ignore_files | call add(ign_files, ig) | endfor
    endif
    let g:p_ign_fpat = '\v('. join(ign_files, '|') .')'

    let g:p_ign_dirs = ""
    if exists('g:vc_ignore_dirs') && type(g:vc_ignore_dirs) == type([])
        let g:vc_ignore_dirs = map(g:vc_ignore_dirs, '"^" . v:val . "[/]$"')
        let g:p_ign_dirs = '\v('.join(g:vc_ignore_dirs, '|').')'
    endif

    if type(get(g:, "vc_ignore_repos", "")) == type([])
        let g:vc_ignore_repos_lst = map(get(g:, "vc_ignore_repos", ""), 's:strip(v:val)')
    else
        let g:vc_ignore_repos_lst = map(split(get(g:, "vc_ignore_repos", ""), ","), 's:strip(v:val)')
    endif
endf
"3}}}

" fuzzy gvars {{{3
fun! s:fuzzy()
    let g:vc_fuzzy_search = (!exists('g:vc_fuzzy_search')) ||
                \ type(eval('g:vc_fuzzy_search')) != type(0) ?
                \ 1 : eval('g:vc_fuzzy_search')
    
    let g:vc_fuzzy_search_result_max = (!exists('g:vc_fuzzy_search_result_max'))  || 
                \ type(eval('g:vc_fuzzy_search_result_max')) != type(0) ? 
                \ 100 : eval('g:vc_fuzzy_search_result_max')

endf
"3}}}

fun! s:strip(input_string) "{{{3
    return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endf
"3}}}

"urls {{{3
fun! s:urls()
    fun! s:initPathVariables(pathvar)
        return exists(a:pathvar) ? s:stripAddSlash(eval(a:pathvar)) : ''
    endf

    fun! s:stripAddSlash(var)
        let val = s:strip(a:var)
        if len(val) > 0 && val[len(val)-1] != '/'
            return val . '/'
        elseif len(val) > 0 | retu val | en
    endf

    fun! s:makelst(varname)
        if !exists(a:varname) | retu [] | en
        if type(eval(a:varname)) == type("")
            retu map(split(eval(a:varname), ","), 's:strip(v:val)')
        elseif type(eval(a:varname)) == type([])
            retu map(eval(a:varname), 's:strip(v:val)')
        else | retur [] | en
    endf

    fun! s:sortrev(a, b)
        retu len(a:a) < len(a:b)
    endf

    let g:p_browse_mylist = s:makelst('g:vc_browse_mylist')
    let g:p_burls = map(s:makelst('g:vc_branch_url'), 's:stripAddSlash(v:val)')
    let g:p_burls = sort(g:p_burls, "s:sortrev")
    let g:p_turl = s:initPathVariables('g:vc_trunk_url')
    let g:p_wcrp = s:initPathVariables('g:vc_working_copy_root_path')
endf
"3}}}

"git {{{3
fun! s:git()
    let g:vc_git_sha_fmt = matchstr(get(g:, 'vc_git_sha_fmt', "short"),'\cshort') != "" ? "%h" : "%H"
    let g:vc_git_log_pfmt = get(g:, 'vc_git_log_pfmt',   "%cn,%ci,%s")
    let g:vc_git_alog_pfmt = get(g:, 'vc_git_alog_pfmt', "%cn,%ci,%s")
endf
"3}}}

fun! s:showerr(msg) "{{{3
    echohl Error | echo a:msg | echohl None
    let ign = input('Press Enter to coninue :')
    retu 0
endf
"3}}}

fun! s:setkeys() "{{{3
    if has('gui_running') 
        let [g:vc_selkey, g:vc_selkey_buf, g:vc_selkey_dscr] = [ "\<c-space>", "<c-space>", "Ctrl-space"]
        let [g:vc_ctrlenterkey, g:vc_ctrlenterkey_buf, g:vc_ctrlenterkey_dscr] = ["\<c-Enter>", "<c-Enter>", "Ctrl-Enter"]
    else
        let [g:vc_selkey, g:vc_selkey_buf, g:vc_selkey_dscr] = ["\<C-f>", "<c-f>", "Ctrl-f"]
        let [g:vc_ctrlenterkey, g:vc_ctrlenterkey_buf, g:vc_ctrlenterkey_dscr] = ["\<C-right>", "<c-right>", "Ctrl-Right"]
    endif
endf
"3}}}

"svnd reference {{{2
"svnd = {
"           idx     : 0
"           title   : str(SVNLog | SVNStatus | SVNCommits | svnurl)
"           meta    : metad ,
"           logd    : logdict
"           statusd : statusdict
"           commitsd : logdict
"           menud     : menudict
"           error     : errd
"           flistd : flistdict
"           browsed : browsedict 
"           bparent  : browse_rhs_path
"       }
"
"flistdict = {
"           contents { idx, flistentryd}
"           ops :
"}
"flistentryd = { line :fpath }
"
"metad = { origurl : svnurl, fpath : absfpath, url: svnurl, wrd: workingrootlocalpath}
"
"logdict = {
"          contents: {idx : logentryd},
"          ops    :
"        }
"logentryd = { line : str, revision : revision_number}
"
"statusdict = {
"          contents: {idx : statusentryd},
"          ops    :
"        }
"statusentryd = { line : str(modtype fpath)  modtype: str, fpath : modified_or_new_fpath}
"
"browsedict = {
"          contents: {idx : fpath},
"          ops    :
"}
"
"menudict = {
"          contents : {idx : menudentryd},
"          ops    :
"}
"menuentryd = {line: str, title: str, callack : funcref, convert:str }
"
"errd = { descr : str , msg: str, line :str, ops: op }
"2}}}

"selectd reference  {{{2
"selectd : {strtohighlight:cache}   log = revision:svnurl,
"selectdict = {
"        key : { line : line, path : path} 
"}
"}}}2
"2}}}
