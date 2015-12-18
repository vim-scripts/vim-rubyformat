# VIM-RUBYFORMAT

`vim-rubyformat` is a simple `vim` plugin, that automatically
reformats/beautifies ruby code, either when a ruby file is saved
or when `ff` is pressed whilst in normal mode.

===========================================================================
#### Installation:
[Vundle Plug-in Manager]: https://github.com/VundleVim/Vundle.vim
###### If using [Vundle Plug-in Manager] for `Vim`:
Add the following line to your vimrc file:
```
Plugin 'radovskyb/vim-rubyformat'
```
Launch `vim` and run `:PluginInstall`
[Pathogen.vim]: https://github.com/tpope/vim-pathogen
[Tim Pope]: https://github.com/tpope
###### If using [Pathogen.vim] by [Tim Pope]:
Go to your terminal window and type:
```
cd ~/.vim/bundle
git clone https://github.com/radovskyb/vim-rubyformat.git
```
===========================================================================

#### Step 1.
In any .rb (ruby) file, when save is called, the RubyFormat() function should automatically be called. It's as simple as that.


#### Step 2 (Optional).
Press ``ff`` in normal mode to call the RubyFormat() function

===========================================================================

### Settings:

For other keybindings, simply bind ``:call RubyFormat()`` to your chosen keybinding in your vimrc file.
Example: ``nnoremap fm :call RubyFormat()<CR>``


``let g:remove_extra_lines = 2`` is the current default, which deletes any
extra blank lines more than 2 in a row. Place in vimrc to change the value.

``let g:strip_trailing_spaces = 1`` is the enabled by default. To disable
simply set the value to ``0``.

===========================================================================

### EXAMPLE REFORMATS:

Before:
```
def   Hello    (   name   )
	 puts "\n-------------"
   	puts "Hello, #{  name }."
 puts '--------------'
end
```
After:
```
def Hello (name)
  puts "\n-------------"
  puts "Hello, #{name}."
  puts '--------------'
end
```
===========================================================================
Before:
```
[ 1, 2, 3,   4,   5  ].each do |   i  |
	 puts "hello"
end
```
After:
```
[1, 2, 3, 4, 5].each do |i| 
  puts "hello"
end
```
===========================================================================
Before:
```
[ 1, 2, 3,   4,   5  ].each {   |  i , b,   c | puts "hello" }
```
After:
```
[1, 2, 3, 4, 5].each { |i , b, c| puts "hello" }
```
===========================================================================
Before:
```
class  Hello
     def    World(  stuff ) 
       end
    end
```
After:
```
class Hello
  def World(stuff) 
  end
end
```
===========================================================================
Before:
```
lambda {puts "hi"
	puts "there"
	}

 lambda {|name|puts "hi"
	puts "there"
}
```
After:
```
lambda {
  puts "hi"
  puts "there"
}

lambda { |name|
  puts "hi"
  puts "there"
}
```
===========================================================================
Before:
```
-> {
	puts "true"}

-> {
	puts "#{itsTrue} #{orIsIt}"}
```
After:
```
-> {
  puts "true"
}

-> {
  puts "#{itsTrue} #{orIsIt}"
}
```
===========================================================================
##### Copyright (C) Benjamin Radovsky <radovskyb@gmail.com>.
##### Distributed under the same terms as Vim itself. See :help license.
