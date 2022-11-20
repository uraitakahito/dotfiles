" When set to "dark", Vim will try to use colors that look good on a dark background. When set to "light", Vim will try to use colors that look good on a light background.
" When this option is set, the default settings for the highlight groups will change. To use other settings, place ":highlight" commands AFTER the setting of the 'background' option.
set background=dark
syntax on

" Number of spaces to use for each step of (auto)indent. Used for 'cindent' , >> , << , etc.
set shiftwidth=2

" To insert space characters whenever the tab key is pressed. With this option set, if you want to enter a real tab character use Ctrl-V<Tab> key sequence.
set expandtab

" To control the number of space characters that will be inserted when the tab key is pressed, set the 'tabstop' option.
set tabstop=2

" Vim will use the clipboard register '*' for all yank, delete, change and put operations which would normally go to the unnamed register.
set clipboard+=unnamed

