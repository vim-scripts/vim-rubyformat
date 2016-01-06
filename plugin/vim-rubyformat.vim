" TODO: MAKE SURE THERE IS ALWAYS AT LEAST ONE SPACE AFTER THE
" START OF ANY LEGITIMATE COMMENTS `#`, BUT NOT INSIDE OF QUOTES ETC.
" TODO: FIX END KEYWORD AND SUCH IN ERB FILES BEING DROPPED
" TODO: MAKE SETTING TO REMOVE EXTRA LINES FROM BOTTOM AND TOP OF FILE
" TODO: MAKE SETTING TO ALLOW TO ENABLE/DISABLE REMOVE TRAILING
" SPACES LINE NUMBER 176
" TODO: LINE NUMBER 178. FIX POSSIBLE MULTIPLE SPACES AFTER
" COMMA NOT BEING DELETED. PLUS CHECK WHOLE FILE MULTIPLE SPACES
" INTO ONE SPACE STUFF. LOOK INTO LINE NUMBER 172, POSSIBLY
" FIX REGEX WITH LOOKBACKS AND LOOKAHEADS/NESTED LOOKSBACKS/LOOKAHEADS
" TODO: USE PROPER SUBSITUTION AND VIMSCRIPT FUNCTIONS RATHER THAN JUST :S
" AND :G, AS WELL AS REFACTOR FUNCTIONS THAT USE LOOKAHEADS AND LOOKBEHINDS
" SUCH AS THE FIRST FEW THAT PUT A SPACE IN APPROPRIATE SPOTS WITH `{`, `[`
" ETC... TO BE ONE FUNCTION THAT TAKES ARGS FOR START AND END ARGS
" TODO: MAKE SURE BLOCKS SUCH AS `if`/`def` ETC... IF ARE EMPTY OR ONLY HAVE FOR
" EXAMPLE A COMMENT INSIDE OF THEM, REMOVE EMPTY LINES
" TODO: ADD HIGH PRIORITY AUTO FORMATTING RULES. LINE 105

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

" TODO: MAKE LOOP OF ARGS ITEMS TO MAKE SURE NOT INSIDE OF INSIDE
" OF PREMADE LIST
function! SubstituteOutsideOfItems(regex, substitution)
	" Example: %s/\(.\{-\}\)\(\s\+\|\s\=\)\(|.\{-\}\)\@<!|\(\(".\{-\}\)\@<=.\{-\}"\|\('.\{-\}\)\@<=.\{-\}'\|\(`.\{-\}\)\@<=.\{-\}`\|\(\/.\{-\}\)\@<=.\{-\}\/\)\@!/\1 |/ge
	execute '%s/'.a:regex.'\(\(".\{-\}\)\@<=.\{-\}"'.'\|\(''.\{-\}\)\@<=.\{-\}'''.'\|\(`.\{-\}\)\@<=.\{-\}`'.'\|\(\/.\{-\}\)\@<=.\{-\}\/'.'\)\@!/'.a:substitution.'/ge'
endfunction

function! RubyFormat()
	" SAVE CURSOR POSITION IN WINDOW BEFORE FORMAT
	let l:winview = winsaveview()
	
	" ALWAYS MAKE SURE THERE IS ONE SPACE AFTER ANY `{` AND BEFORE ANY `}`
	" THAT IS NOT INSIDE OF QUOTES
	" call SubstituteOutsideOfItems('{\(\s\+\|\s\=\)', '{ ')
	:g!/^}/s/\(\s\+\|\s\=\)}\(\(".\{-\}\)\@<=.\{-\}"\|\('.\{-\}\)\@<=.\{-\}'\|\(`.\{-\}\)\@<=.\{-\}`\|\(\/.\{-\}\)\@<=.\{-\}\/\)\@!/ }/ge

	" REPLACE ANY SPACES AFTER ANY `(` OR BEFORE ANY `)` AS LONG AS
	" IT ISN'T INSIDE OF QUOTES
	call SubstituteOutsideOfItems('(\(\s\+\|\s\=\)', '(')
	call SubstituteOutsideOfItems('\(\s\+\|\s\=\))', ')')

	" REPLACE ANY SPACES AFTER ANY `[` OR BEFORE ANY `]` AS LONG AS
	" IT ISN'T INSIDE OF QUOTES
	call SubstituteOutsideOfItems('\[\(\s\+\|\s\=\)', '[')
	call SubstituteOutsideOfItems('\(\s\+\|\s\=\)\]', ']')
	" %s/\s\(\s\+\|\s\=\)\]\(\(".\{-\}\)\@<=.\{-\}"\|\('.\{-\}\)\@<=.\{-\}'\|\(`.\{-\}\)\@<=.\{-\}`\|\(\/.\{-\}\)\@<=.\{-\}\/\)\@!/]/ge

	" DELETE ANY SPACE CHARACTERS AFTER THE START OF A 
	" STRING INTERPOLATION `#{` OR BEFORE THE END `}`
	:%s/#{\(\s\+\|\s\=\)\(.\{-\}\)\(\s\+\|\s\=\)}/#{\2}/ge

	" ADD A SPACE BEFORE ANY `{` IF THERE IS ANYTHING BEFORE IT AND IS
	" NOT INSIDE OF ANY QUOTES
	call SubstituteOutsideOfItems('\(.\{-\}\)\(\s\+\|\s\=\){', '\1 {')
	
	" MAKE SURE KEYWORDS SUCH AS `class` OR `def`
	" START ON THEIR OWN LINE AND DO NOT HAVE CODE BEFORE IT
	" ALTHOUGH IF THE KEYWORD CLASS IS BEING USED IN THE
	" CONTEXT OF `object.class` DO NOT CREATE EMPTY LINES
	:g!/^\s\{-\}\(\<class\C\>\|\<def\C\>\)\|[^"]\{-\}#/s/\([^\n\|^.\|^#]\)\(\(\<class\>\C\|\<def\>\C\).*\)/\1\r\r\2/ge

	" REPLACE `puts...` WITH `puts ...`
	%s/puts\(\S.*\)/puts \1/ge

	" REPLACE ANY `|` FOLLOWED OR PREPENDED BY ONE OR MORE
	" SPACES WITH A SINGLE `|`, E.G. `| name |` BECOMES `|name|`
	" IF NOT SURROUNDED BY QUOTES ET CETERA
	call SubstituteOutsideOfItems('|\(\s\+\|\s\=\)\|\(\s\+\|\s\=\)|', '|')

	" PUT A SPACE BEFORE ANY `|` THAT HAS SOMETHING BEFORE IT, BUT DOES NOT
	" HAVE ANY OTHER `|` BEFORE IT OR ISN'T INSIDE OF QUOTES
	call SubstituteOutsideOfItems('\(.\{-\}\)\(\s\+\|\s\=\)\(|.\{-\}\)\@<!|', '\1 |')
	
	" MAKE SURE THERE IS ALWAYS 1 SPACE BEFORE ANY `|...|`
	" IF NOT SURROUNDED BY QUOTES ET CETERA
	call SubstituteOutsideOfItems('\(\s\=\|\s\+\)|\(.\{-\}\)|\(\s\=\|\s\+\)', ' |\2|')

	" MAKE SURE THERE IS ALWAYS 1 SPACE ANY `|...|` IF THERE
	" IS ANY CHARACTERS FOLLOWING EXCEPT FOR SPACES AND ALSO
	" IF NOT SURROUNDED BY QUOTES ET CETERA
	call SubstituteOutsideOfItems('|\(.\{-\}\)|\(\s\=\|\s\+\)\(\S\)\@=', '|\1| ')
	
	" REFACTORED TO HERE: ---------------------------------------------------

	" TODO: DO BELOW 3 REGEX METHODS BELOW WITH DO BLOCKS ---HIGH PRIORITY---

	" TODO: REDO
	" def hello {|name|puts "sup"
	"   puts "hello"}
	" BECOMES
	" def hello { |name|
	"   puts "sup"
	"   puts "hello"
	" }
	:g!/.*{\s\{-\}|.\{-\}|\s\+$\|.*{.*}\(.call.*\)\=\s\{-\}$/s/\(.*\s\{-\}{\s\{-\}\(|.\{-\}|\)\s\{-\}.\{-\}\)\([^\r]\)/\1\r\t\3/ge

	" TODO: REDO
	" def hello {puts "sup"
	"   puts "hello"}
	" BECOMES
	" def hello {
	"   puts "sup"
	"   puts "hello"
	" }
	:g!/{\s\+\([^\n]\+\)\@!\|.*["\|'\|`].*{.*\|.*{.*["\|'\|`].*{\|.*{.*}\(.call.*\)\=$\|.*{\s\{-\}\(|.\{-\}|\).*/s/\(.*{\s\{-\}\)\([^\r]\)/\1\r\t\2/ge

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
		:g!/["\|`\|']\s\{-}$\|.*["\|`].*}.*["\|`].*\|.*{.*}\(.call.*\)\=\(\s\=\|\s\+\)$/s/\([^\r]\)\(.*\)\([^\r]\+\)}/\1\2\3\r}/ge
	endif
	
	" THIS IS THE SAME AS THE ABOVE, EXCEPT WILL STILL WORK LIKE THIS:
	" THE #{} INTERPOLATION WOULD STOP THE ABOVE REGEX FROM WORKING.
	" def hello {
	" puts "#{name}"}
	:g!/[^#]{.*}\s\{-\}$/s/\(.*".*#{.*\)}\s\{-\}$/\1\r}/ge
	
	" REPLACE MULTIPLE WHITE SPACE CHARACTERS WITH A SINGLE SPACE
	" IF NOT SURROUNDED BY QUOTES ET CETERA
	call SubstituteOutsideOfItems('\s\+', ' ')

	" TODO: CREATE A SETTING FOR ENABLING/DISABLING THIS REGEX
	" REMOVE EXTRA WHITE SPACE FROM THE END OF ANY LINE
	:%s/\s\+$//ge

	:%s/,\s\=/, /ge " MAKE SURE NOT INSIDE OF QUOTES

	" REMOVE EXTRA LINES AFTER A COMMA
	%s/,\n\+/,\r/ge " MAKE SURE NOT INSIDE OF QUOTES

	" REMOVE EXTRA LINES FROM CONFIG VARIABLE g:remove_extra_lines = 3
	:execute '%s/\n\{'.g:remove_extra_lines.'\}\n\+/'.g:lines.'/ge'

	" MAKE SURE THERE IS ALWAYS AT LEAST ONE EMPTY
	" LINE AFTER ANY `}` IF IT ISNT THE LAST `}`
	" IN THE FILE
	:g/}.\{-\}\n\(\n\+\)\@!\([^\n]\)\@=/s/^\(.*\)}\(.\{-\}\)\(.\{-\}\n.\{-\}}\)\@!\s\{-\}$/\1}\2\r/ge

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
	" autocmd FileType eruby autocmd BufWritePre <buffer> :silent! call RubyFormat()
	" TEMPORARILY DISABLE TILL FIX
endif
