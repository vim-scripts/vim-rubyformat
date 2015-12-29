" INDENTATION SETTINGS
filetype plugin indent on
set autoindent
set smarttab
set smartindent
au FileType ruby set tabstop=2 shiftwidth=2 softtabstop=2

if !exists("g:rubyformat_on_save")
	let g:rubyformat_on_save = 1
endif

if !exists("g:remove_extra_lines")
	let g:remove_extra_lines = 2
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

	" ALWAYS MAKE SURE THERE IS ONE SPACE AFTER ANY `{` AND BEFORE ANY `}`
	" THAT IS NOT INSIDE OF QUOTES
	:%s/\(["\|'\|`].\{-\}\)\@<!{\s\=\s\{-\}\(.\{-\}\)\s\{-\}\s\=}\(.\{-\}["\|`\|'\|}]\)\@!/{ \2 }/ge
	" TODO: FIX ISSUE OF {} IF IN LINE SUCH AS `hello{stuff{}}`: TEMPORARY FIX
	:%s/\(["\|'].\{-\}\)\@<!{}\(.\{-\}["\|']\)\@!/{ }/ge

	" DELETE ANY SPACE CHARACTERS AFTER THE START OF A 
	" STRING INTERPOLATION `#{` OR BEFORE THE END `}`
	:%s/#{\(\s\+\|\s\=\)\(.\{-\}\)\(\s\+\|\s\=\)}/#{\2}/ge

	" ADD A SPACE BEFORE ANY `{` IF THERE IS ANYTHING BEFORE IT AND IS
	" NOT INSIDE OF ANY QUOTES
	:%s/\(.\{-\}\)\s\=\s\{-\}\(["\|'\|`].\{-\}\)\@<!{/\1 {/ge
	
	" MAKE SURE KEYWORDS SUCH AS `class` OR `def`
	" START ON THEIR OWN LINE AND DO NOT HAVE CODE BEFORE IT
	" ALTHOUGH IF THE KEYWORD CLASS IS BEING USED IN THE
	" CONTEXT OF `object.class` DO NOT CREATE EMPTY LINES
	:g!/^\s\{-\}\(\<class\C\>\|\<def\C\>\)\|[^"]\{-\}#/s/\([^\n\|^.\|^#]\)\(\(\<class\>\C\|\<def\>\C\).*\)/\1\r\r\2/ge

	" REPLACE ANY SPACES AFTER ANY `(` OR BEFORE ANY `)` AS LONG AS
	" IT ISN'T INSIDE OF QUOTES
	:%s/\(\s\+\|\s\=\)\(["\|'].\{-\}\)\@<!\()\)\|\((\)\(\s\+\|\s\=\)\(.\{-\}["\|']\)\@!/\3\4/ge

	" REPLACE ANY SPACES AFTER ANY `[` OR BEFORE ANY `]` AS LONG AS
	" IT ISN'T INSIDE OF QUOTES
	:%s/\(\s\+\|\s\=\)\(["\|'].\{-\}\)\@<!\(\]\)\|\(\[\)\(\s\+\|\s\=\)\(.\{-\}["\|']\)\@!/\3\4/ge

	" REPLACE `puts...` WITH `puts ...`
	%s/puts\(\S.*\)/puts \1/ge

	" REPLACE ANY `|` FOLLOWED OR PREPENDED BY ONE OR MORE
	" SPACES WITH A SINGLE `|`, E.G. `| name |` BECOMES `|name|`
	:%s/\(["\|'].\{-\}\)\@<!|\(\s\+\|\s\=\)\|\(\s\+\|\s\=\)|\(.\{-\}["\|']\)\@!/|/ge

	" PUT A SPACE BEFORE ANY `|` THAT HAS SOMETHING BEFORE IT, BUT DOES NOT
	" HAVE ANY OTHER `|` BEFORE IT OR ISN'T INSIDE OF QUOTES
	:%s/\(.\{-\}\)\(\s\+\|\s\=\)\([|\|"\|'].\{-\}\)\@<!|/\1 |/ge
	
	" REFACTORED TO HERE: ---------------------------------------------------

	" REPLACE ANYTHING LIKE `{|i|   ` WITH `{|i|`
	" IF THE LINE DOESN'T END WITH A `}`
	:g!/|\(.\{-\}\)|\(.\{-\}\)}$/s/|\(.*\)|\(.\{-\}\)\(\s\{-\}\)\(\S\)/|\1| \4/ge

	" REPLACE `{ |...|...}` WITH `{ |...| ...}` ON LINES
	" THAT START WITH `{ |...|...`, WITH ANYTHING IN BETWEEN, THAT
	" ENDS WITH A `}` AND DOES NOT HAVE A SPACE `{ |...|` <- HERE
	" :g/|\(.*\)|\(\S\)\(.*\)}$/s/|\(.*\)|\(\s\+\|\s\=\)\(.*\)}$/|\1| \3}/ge
	:%s/\(|.\{-\}|\)\(\s\+\|\s\=\)/\1 /ge

	" TODO: DO BELOW 3 REGEX METHODS BELOW WITH DO BLOCKS

	" TODO: REDO
	" def hello {|name|puts "sup"
	"   puts "hello"}
	" BECOMES
	" def hello { |name|
	"   puts "sup"
	"   puts "hello"
	" }
	:g!/.*{\s\{-\}|.\{-\}|\s\+$\|.*{.*}\(.call.*\)\=$/s/\(.*\s\{-\}{\s\{-\}\(|.\{-\}|\)\s\{-\}.\{-\}\)\([^\r]\)/\1\r\t\3/ge

	" TODO: REDO
	" def hello {puts "sup"
	"   puts "hello"}
	" BECOMES
	" def hello {
	"   puts "sup"
	"   puts "hello"
	" }
	:g!/.*["\|'\|`].*{.*\|.*{.*["\|'\|`].*{\|.*{.*}\(.call.*\)\=$\|.*{\s\{-\}\(|.\{-\}|\).*/s/\(.*{\s\{-\}\)\([^\r]\)/\1\r\t\2/ge

	" SAME AS THE ABOVE BUT ALLOWS FOR `def hello { puts "#{}" ... \n }`
	:g!/{\({\)\@<!.*\|.*{.*}$\|".*["]\+.*{.*["]\+.*"\|.*{\s\{-\}\(|.\{-\}|\).*/s/\(.*{\s\{-\}\)\(.*".*{.*".*\)/\1\r\t\2/ge

	" do puts "hello"
	"   puts "there"
	" end
	" BECOMES
	" do
	"   puts "hello"
	"   puts "there"
	" end
	:g!/[^"]\{-\}#\|".*\<do\>.*"\|.*\<do\>.\{-\}\<end\>\|.*\<do\>.\{-\}|/s/\(.*\)\<do\>\([^\n]\)/\1do\r\2/ge
	
	" do
	"   puts "hello" end
	" BECOMES
	" do
	"   puts "there"
	" end
	" HOWEVER THE ABOVE WON'T MOVE THE END KEYWORD DOWN
	" IT'S IN A LINE THAT LOOKS LIKE THE FOLLOWING:
	" `5.times do puts "hey" end` <- WHERE BOTH KEYWORD AND END ARE
	" ON THE SAME LINE. THE SAME GOES FOR `if true do puts "it's true" end`
	:g!/^\s\{-}\<end\>\|^\s\{-}#\|^\s\{-\}\<if\|do\>/s/\([^\n\|^\s\|^\t]\)\<end\>/\1\rend/ge

	" IF NOT IN THE SAME LINE STYLE OF `def hello { puts "hello" }`
	" def hello {
	"   puts "hello"}
	" BECOMES
	" def hello {
	"   puts "hello"
	" }
	if &ft != 'eruby' " FOR RUBY FILES THAT AREN'T ERUBY FILETYPE
		" TODO: MAKE SURE THIS IS WORKING FOR RUBY FILES
		:g!/["\|`\|']\s\{-}$\|.*["\|`].*}.*["\|`].*\|.*{.*}\(.call.*\)\=$/s/\([^\r]\)\(.*\)\([^\r]\+\)}/\1\2\3\r}/ge
	endif
	
	" THIS IS THE SAME AS THE ABOVE, EXCEPT WILL STILL WORK LIKE THIS:
	" THE #{} INTERPOLATION WOULD STOP THE ABOVE REGEX FROM WORKING.
	" def hello {
	" puts "#{name}"}
	:g!/[^#]{.*}\s\{-\}$/s/\(.*".*#{.*\)}\s\{-\}$/\1\r}/ge
	
	" REPLACE MULTIPLE WHITE SPACE CHARACTERS WITH A SINGLE SPACE
	" AS LONG AS THE SPACE DOESNT CONTAIN QUOTES BEFORE OR AFTER THE
	" SPACE ACHIEVED USING NEGATIVE LOOKAHEAD AND NEGATIVE LOOKBEHING
	" REGULAR EXPRESSIONS
	:%s/\s\+\(["\|'].*\|'.*\)\@<!\|\s\+\(.*"\|.*'\)\@!/ /ge 

	" REMOVE EXTRA WHITE SPACE FROM ANY LINE
	:%s/\s\+$//ge
	:%s/,\s\=/, /ge " MAKE SURE NOT INSIDE OF QUOTES

	" REMOVE EXTRA LINES AFTER A COMMA
	%s/,\n\+/,\r/e " MAKE SURE NOT INSIDE OF QUOTES

	" REMOVE EXTRA LINES FROM CONFIG VARIABLE g:remove_extra_lines = 3
	:execute '%s/\n\{'.g:remove_extra_lines.'\}\n\+/'.g:lines.'/ge'

	" REMOVE ANY EMPTY LINES FROM THE TOP OF THE PAGE
	" DOWN UNTIL THE FIRST LINE OF CODE/COMMENT
	:g/^\(\n\)\@<!$/s/\n\+//ge

	" ADD SPACING TO ANYTHING IN AN ERUBY FILE THAT STARTS OR ENDS WITH `<%` OR `%>`
	if &ft == 'eruby'
		:g!/-%>/s/\(\S\)%>/\1 %>/ge
		:g!/<%=\|<%-\|<%#/s/<%\(\S\)/<% \1/ge
		%s/<%#\(\S\)/<%# \1/ge
		%s/<%=\(\S\)/<%= \1/ge
		%s/<%-\(\S\)/<%- \1/ge
		%s/\(\S\)-%>/\1 -%>/ge
	endif

	" ON A LINE THAT STARTS WITH THE KEYWORD `end`, MOVE ANYTHING AFTER IT
	" TO IT'S OWN LINE AS WELL AS MAKE SURE THAT ANYTHING THAT COMES AFTER
	" THE KEYWORD `end` HAS AT LEAST ONE EMPTY LINE BETWEEN THEM
	:g!/^\s\{-\}\<end\>\([.call.*\|\n\+]\)\|\(\s\+\n\+\)/s/^\(\s\{-\}\<end\>\)\n\=\([^\n]\)/\1\r\r\2/ge

	" RUN VIM'S REGULAR REINDENT TO FIX ANY GENERAL INDENT ISSUES
	:normal gg=G

	" GO BACK TO CURSOR POSITION IN WINDOW AFTER FORMAT
	:call winrestview(l:winview)
endfunction

" BIND THE FUNCTION CALL TO THE KEYPRESS `ff`
au FileType ruby nnoremap <buffer> ff :silent! call RubyFormat()<CR>

" CALL THE `RubyFormat` FUNCTION ON SAVE IF INSIDE A RUBY FILE
" IF `g:rubyformat_on_save > 0`
if g:rubyformat_on_save > 0
	autocmd FileType ruby autocmd BufWritePre <buffer> :silent! call RubyFormat()

	" DO THE SAME AS THE ABOVE `autocmd` BUT FOR ERUBY FILES
	" TODO: ADD MORE SPECIFIX ERB BASED REFORMATTING
	autocmd FileType eruby autocmd BufWritePre <buffer> :silent! call RubyFormat()
endif
