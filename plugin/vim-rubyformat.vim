" indentation settings
filetype plugin indent on
set autoindent
set smarttab
set smartindent
au FileType ruby set tabstop=2 shiftwidth=2 softtabstop=2

if !exists("g:remove_extra_lines")
	let g:remove_extra_lines = 2
endif

if !exists("g:strip_trailing_spaces")
	let g:strip_trailing_spaces = 1
endif

let g:lines = ""
let i = 0
while i <= g:remove_extra_lines
	let g:lines .= "\r"
	let i += 1
endwhile

function! RubyFormat()
	" SAVE CURSOR POSITION IN WINDOW BEFORE FORMAT
	:let l:winview = winsaveview()
	
	" MAKE A SPACE BETWEEN ANY `{` OR `}` CHARACTERS ON LINES THAT DO NOT CONTAIN INTERPOLATION
	:g!/[^"]\+#{/s/\(\S\{-\}\){\s\{-\}\(\S\+\)/\1{ \2/ge
	:g!/[^"]\+.*#{/s/\(\S\{-\}\)\s\{-\}\(\S\+\)}/\1 \2 }/ge

	" MAKE A SPACE BETWEEN ANY `{` OR `}` CHARACTERS ON LINES THAT DO CONTAIN INTERPOLATION
	:g/[^"]\+#{/s/\([^#]\{-\}\){\s\{-\}\(\S\+\)/\1{ \2/ge
	:g/[^"]\+#{/s/\([^#]\+\){/\1 {/ge
	" NOW REMOVE THE EXTRA SPACES CREATED IN THE ABOVE REGEX SUBSTITUTION
	%s/\s\+{/ {/ge

	" DELETE ANY SPACE CHARACTERS AFTER THE START OF A 
	" STRING INTERPOLATION `#{` OR BEFORE THE END `}`
	:%s/#{\s\+\(.\{-\}\)\s\+}/#{\1}/ge
	:%s/#{\(.\{-\}\)\s\+}/#{\1}/ge
	:%s/#{\s\+\(.\{-\}\)}/#{\1}/ge

	" AFTER RUNNING THE ABOVE 3 REGEX, ONLY THEN, TO KEEP THE CORRECT ORDER MAKE A
	" SPACE BEFORE A `}` AT THE END OF A LINE THAT CONTAINS INTERPOLATION
	:g/[^"]\+".*#{/s/\(\S\+\)}\s\{-\}$/\1 }/ge

	" ADD A SPACE BEFORE ANY `{` THAT IS PREPENDED BY ANYTHING AND IS THE
	" FIRST `{` IN THE LINE
	:%s/^\([^#]\{-\}\)\s\{-\}{/\1 {/ge

	" REPLACE ANY `(` FOLLOWED BY ONE OR MORE SPACES WITH A SINGLE `(`
	:%s/(\s\+/(/ge

	" REPLACE ANY `)` PREPENDED BY ONE OR MORE SPACES WITH A SINGLE `)`
	:%s/\s\+)/)/ge

	" REPLACE ANY `[` FOLLOWED BY ONE OR MORE SPACES WITH A SINGLE `[`
	:%s/\[\s\+/[/ge
	
	" REPLACE ANY `]` PREPENDED BY ONE OR MORE SPACES WITH A SINGLE `]`
	:%s/\s\+\]/]/ge

	" REPLACE `->{` WITH `-> {`
	%s/->{/-> {/ge

	" REPLACE `puts...` WITH `puts ...`
	%s/puts\(\S.*\)/puts \1/ge

	" REPLACE ANY `|` FOLLOWED OR PREPENDED BY ONE OR MORE
	" SPACES WITH A SINGLE `|`, E.G. `| name |` BECOMES `|name|`
	:%s/|\s\+/|/ge
	:%s/\s\+|/|/ge

	" REPLACE ANY `do|` WITH `do |`
	:%s/do|/do |/ge

	" REPLACE ANYTHING LIKE `{|i|   ` WITH `{|i|`
	" IF THE LINE DOESN'T END WITH A `}`
	:g!/|\(.*\)|\(.*\)}$/s/|\(.*\)|\(.\{-\}\)\(\s\{-\}\)\(\S\)/|\1| \4

	" REPLACE `{ |...|...}` WITH `{ |...| ...}` ON LINES
	" THAT START WITH `{ |...|...`, WITH ANYTHING IN BETWEEN, THAT
	" ENDS WITH A `}` AND DOES NOT HAVE A SPACE `{ |...|` <- HERE
	:g/|\(.*\)|\(\S\)\(.*\)}$/s/|\(.*\)|\(.*\)}$/|\1| \2}/ge

	" PUT A SPACE AFTER A `{` AND BEFORE THE `|`
	" E.G. `def hello{|name| ... }` BECOMES `def hello{ |name| ... }`
	:%s/{|/{ |/ge
	" PUT A SPACE AFTER A `|` AND BEFORE THE `}`
	:%s/|}/| }/ge
	
	" TODO: DO BELOW 3 REGEX METHODS BELOW WITH DO BLOCKS
	
	" `def hello {|name|puts "sup"
	"	puts "hello"}`
	" BECOMES
	" `def hello { |name|
	"	puts "sup"
	"	puts "hello"
	" }`
	:g!/.*{.*}$/s/\(.*\s\{-\}{\s\{-\}\(|.*|\)\s\{-\}.\{-\}\)\([^\r]\)/\1\r\t\3/ge

	" `def hello {puts "sup"
	"	puts "hello"}`
	" BECOMES
	" `def hello {
	"	puts "sup"
	"	puts "hello"
	" }`
	:g!/.*".*{.*\|.*{.*".*{\|.*{.*}$\|.*{\s\{-\}\(|.\{-\}|\).*/s/\(.*{\s\{-\}\)\([^\r]\)/\1\r\t\2/ge

	" SAME AS THE ABOVE BUT ALLOWS FOR `def hello { puts "#{}" ... \n }`
	:g!/.*{.*}$\|".*["]\+.*{.*["]\+.*"\|.*{\s\{-\}\(|.\{-\}|\).*/s/\(.*{\s\{-\}\)\(.*".*{.*".*\)/\1\r\t\2/ge

	" REPLACE ANYTHING LIKE `` WITH `` IF IT DOESN'T CONTAIN ALL OF
	" THE START FOLLOWED BY `{` FOLLOWED BY ANYTHING AND ENDING WITH `}`
	" ALL ON THE SAME LINE, E.G. `def hello { puts "hello" }`
	" `def hello {
	"	puts "hello"}`
	" BECOMES
	" `def hello {
	"	puts "hello"
	" }`
	if &ft != 'eruby' " FOR RUBY FILES THAT AREN'T ERUBY FILETYPE
		" TODO: MAKE SURE THIS IS WORKING FOR RUBY FILES
		:g!/.*".*}.*".*\|.*{.*}$/s/\([^\r]\)\(.*\)}/\1\2\r}/ge
	endif
	
	" THIS IS THE SAME AS THE ABOVE, EXCEPT WILL STILL WORK LIKE THIS:
	" THE #{} INTERPOLATION WOULD STOP THE ABOVE REGEX FROM WORKING.
	" `def hello {
	" puts "#{name}"}`
	:g!/[^#]{.*}\s\{-\}$/s/\(.*".*#{.*\)}\s\{-\}$/\1\r}/ge
	" :g!/.*[^#]{.*}$\|.*["]\+.*#{.*/s/\([^\r]\)}$/\1\r}/ge
	
	" REPLACE MULTIPLE WHITE SPACE CHARACTERS WITH A SINGLE SPACE
	:g!/"[^"]\+"\|'[^']\+'/s/\s\+/ /ge 
	" REPLACE MULTIPLE WHITE SPACE CHARACTERS WITH A SINGLE SPACE
	" ON LINES THAT CONTAIN QUOTES
	:g/"[^"]\+"\|'[^']\+'/s/\s\+"\(.\{-\}\)"/ "\1"/ge 
	:g/"[^"]\+"\|'[^']\+'/s/\s\+\("[^"]\{-\}"\)\s\+/ \1 /ge 

	" REMOVE TRAILING WHITE SPACE FROM ANY LINE
	if g:strip_trailing_spaces > 0 
		%s/\s\+$//e
	endif
	
	" REMOVE EXTRA LINES FROM CONFIG VARIABLE g:remove_extra_lines = 3
	:execute '%s/\n\{'.g:remove_extra_lines.'\}\n\+/'.g:lines.'/ge'

	" SAME AS ABOVE BUT DOES NOT DELETE LINES UNTIL TEXT APEARS
	" :execute 'g!/^$\n\+.*/s/\n\{'.g:remove_extra_lines.'\}\n\+/'.g:lines.'/ge'

	" REMOVE EXTRA LINES AFTER A COMMA
	%s/,\n\+/,\r/e

	" ADD SPACING TO ANYTHING IN AN ERUBY FILE THAT STARTS OR ENDS WITH `<%` OR `%>`
	if &ft == 'eruby'
		:g!/-%>/s/\(\S\)%>/\1 %>/ge
		:g!/<%=\|<%-\|<%#/s/<%\(\S\)/<% \1/ge
		%s/<%#\(\S\)/<%# \1/ge
		%s/<%=\(\S\)/<%= \1/ge
		%s/<%-\(\S\)/<%- \1/ge
		%s/\(\S\)-%>/\1 -%>/ge
	endif

	" RUN VIM'S REGULAR REINDENT TO FIX ANY GENERAL INDENT ISSUES
	:normal gg=G

	" GO BACK TO CURSOR POSITION IN WINDOW AFTER FORMAT
	:call winrestview(l:winview)
endfunction

" BIND THE FUNCTION CALL TO THE KEYPRESS `ff`
au FileType ruby nnoremap <buffer> ff :silent! call RubyFormat()<CR>

" CALL THE `RubyFormat` FUNCTION ON SAVE IF INSIDE A RUBY FILE
autocmd FileType ruby autocmd BufWritePre <buffer> :silent! call RubyFormat()

" DO THE SAME AS THE ABOVE `autocmd` BUT FOR ERUBY FILES
" TODO: ADD MORE SPECIFIX ERB BASED REFORMATTING
autocmd FileType eruby autocmd BufWritePre <buffer> :silent! call RubyFormat()
