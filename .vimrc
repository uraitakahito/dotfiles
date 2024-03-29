" See Also:
" https://stackoverflow.com/questions/44867116/where-is-the-default-vimrc-located-on-mac
if has('macunix')
  unlet! skip_defaults_vim
  source $VIMRUNTIME/defaults.vim
endif

" When there is a previous search pattern, highlight all its matches.
" https://vimhelp.org/options.txt.html#%27hlsearch%27
set hlsearch

" Stop the highlighting for the 'hlsearch' option. Type: <Esc><Esc>
" https://vimhelp.org/pattern.txt.html#%3Anohlsearch
" https://vimhelp.org/map.txt.html#%3Anmap
nmap <Esc><Esc> :nohlsearch<Enter>

" Number of spaces to use for each step of (auto)indent. Used for 'cindent' , >> , << , etc.
set shiftwidth=2

" To insert space characters whenever the tab key is pressed. With this option set, if you want to enter a real tab character use Ctrl-V<Tab> key sequence.
set expandtab

" To control the number of space characters that will be inserted when the tab key is pressed, set the 'tabstop' option.
set tabstop=2

" Vim will use the clipboard register '*' for all yank, delete, change and put operations which would normally go to the unnamed register.
set clipboard+=unnamed

