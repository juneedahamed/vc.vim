" =============================================================================
" File:         plugin/vc.vim
" Description:  Plugin for svn, git, hg, bzr 
" Author:       Juneed Ahamed
" License:      Distributed under the same terms as Vim itself. See :help license.
" =============================================================================

"plugin/vc.vim "{{{

"init "{{{
if (exists('g:loaded_vc') && g:loaded_vc) || v:version < 700 || &cp
	fini
en
if !exists('g:vc_glb_init') | let g:vc_glb_init = vc#globals#init() | en
let g:loaded_vc = 1
"}}}

"command mappings "{{{
com! -n=* -com=customlist,vc#cmpt#Status VCStatus call vc#status#Status(<f-args>)
com! -n=* -com=customlist,vc#cmpt#Blame VCBlame call vc#Blame(<f-args>)
com! -n=* -com=customlist,vc#cmpt#Info VCInfo call vc#Info(<f-args>)
com! -n=* -com=customlist,vc#cmpt#Diff -bang VCDiff call vc#Diff(<q-bang>, 1, <f-args>)
com! -n=* -com=customlist,vc#cmpt#Log -bang VCLog call vc#log#Log(<q-bang>, <f-args>)
com! -n=* -com=customlist,vc#cmpt#Move -bang VCMove call vc#MoveCopy(<q-bang>, "move", <f-args>)
com! -n=* -com=customlist,vc#cmpt#Copy -bang VCCopy call vc#MoveCopy(<q-bang>, "copy", <f-args>)
com! -n=* -com=customlist,vc#cmpt#Revert -bang VCRevert call vc#Revert(<q-bang>, <f-args>)

com! -n=* -com=customlist,vc#cmpt#Add -bang VCAdd call vc#add#Add(<q-bang>, <f-args>)
com! -n=* -com=customlist,vc#cmpt#Commit -bang VCCommit call vc#commit#Commit(<q-bang>, <f-args>)

com! VCBrowse call vc#browse#Menu()
com! VCBrowseMyList call vc#mylist#Browse()
com! VCBrowseBookMarks call vc#bookmarks#Browse()
com! VCBrowseBuffer call vc#buffer#Browse()

com! -n=* -com=dir VCBrowseWorkingCopy call vc#browse#Local(0, <f-args>)
com! -n=* -com=dir VCBrowseWorkingCopyRec call vc#browse#Local(1, <f-args>)
com! -n=* -com=customlist,vc#cmpt#BrowseRepo VCBrowseRepo call vc#browse#SVNRepo(<f-args>)

com! VCClearCache call vc#caop#ClearAll()

com! -n=1 -com=customlist,vc#cmpt#Repos VCDefaultrepo call vc#Defaultrepo(<q-args>)
com! -n=* -com=customlist,vc#cmpt#Push VCPush call vc#PushPullFetch("push", <f-args>)
com! -n=* -com=customlist,vc#cmpt#Pull VCPull call vc#PushPullFetch("pull", <f-args>)
com! -n=* -com=customlist,vc#cmpt#Fetch VCFetch call vc#PushPullFetch("fetch", "-git", <f-args>)

if index(vc#repos#repos(), "-hg") >= 0
    com! -n=* -com=customlist,vc#cmpt#Incoming VCIncoming call vc#HgInOut("incoming", "Incoming","-hg", <f-args>)
    com! -n=* -com=customlist,vc#cmpt#Outgoing VCOutgoing call vc#HgInOut("outgoing", "Outgoing", "-hg", <f-args>)
endif

com! -n=* VCGrep call vc#grep#do("", <q-args>)

if !exists("g:no_vc_maps") || g:no_vc_maps == 0
    nmap + :<C-u>call vc#grep#do("*".fnamemodify(expand('%'), ':e'), expand("<cword>")) <CR>
    vmap + :<C-u>call vc#grep#do("*".fnamemodify(expand('%'), ':e'), expand("<cword>")) <CR>
endif

"}}}

"leader mappings "{{{
if exists('g:vc_allow_leader_mappings') && g:vc_allow_leader_mappings == 1
    map <silent> <leader>B :VCBlame<CR>
    map <silent> <leader>d :VCDiff<CR>
    map <silent> <leader>df :VCDiff!<CR>
    map <silent> <leader>s :VCStatus<CR>  
    map <silent> <leader>su :VCStatus -u<CR>
    map <silent> <leader>sq :VCStatus -qu<CR>
    map <silent> <leader>sc :VCStatus .<CR>
    map <silent> <leader>l :VCLog!<CR>
    map <silent> <leader>b :VCBrowse<CR>
    map <silent> <leader>bm :VCBrowse<CR>
    map <silent> <leader>bw :VCBrowseWorkingCopy<CR>
    map <silent> <leader>br :VCBrowseRepo<CR>
    map <silent> <leader>bl :VCBrowseMyList<CR>
    map <silent> <leader>bb :VCBrowseBookMarks<CR>
    map <silent> <leader>bf :VCBrowseBuffer<CR>
    map <silent> <leader>q :diffoff! <CR> :q<CR>
endif
"}}}

call vc#EnableBufferSetup()

