set nocompatible 
set history=100
set lcs=tab:\¦\ 
filetype on
filetype plugin on
filetype indent on 
set autoread 
set mouse=c 
syntax enable 
set cursorline
hi cursorline guibg=#00ff00
hi CursorColumn guibg=#00ff00
set foldenable
set foldmethod=manual
set foldcolumn=0
setlocal foldlevel=3
set foldclose=all           
nnoremap <space> @=((foldclosed(line('.')) < 0) ? 'zc' : 'zo')<CR>
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
set smarttab
set ai  
set si 
set wrap 
set sw=4		
set wildmenu 
set ruler 
set cmdheight=1 
set lz 
set backspace=eol,start,indent 
set whichwrap+=<,>,h,l 
set magic 
set noerrorbells
set novisualbell
set showmatch 
set mat=4 
set hlsearch
set ignorecase
set encoding=utf-8
set fileencodings=utf-8
set termencoding=utf-8
set smartindent
set cin
set showmatch
set guioptions-=T
set guioptions-=m
set vb t_vb=
set laststatus=4
set pastetoggle=<F9>
set background=dark
highlight Search ctermbg=black  ctermfg=white guifg=white guibg=black
autocmd BufNewFile *.py,*.cc,*.sh,*.java exec ":call SetTitle()"
func SetTitle()  
    if expand("%:e") == 'sh'  
        call setline(1, "#!/bin/bash")
        call setline(2, "##############################################################")  
        call setline(3, "# File Name: ".expand("%"))
        call setline(4, "# Time: ".strftime("%F-%T"))
        call setline(5, "# Author: ")
        call setline(6, "# Organization: www.gk.com")
        call setline(7, "##############################################################")
    endif  
endfunc 
