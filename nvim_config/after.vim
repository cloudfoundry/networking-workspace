colorscheme base16-gruvbox-dark-hard

if filereadable(expand("~/.vimrc_background"))
  source ~/.vimrc_background
endif

let g:go_rename_command = 'gopls'
