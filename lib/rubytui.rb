# -*- Ruby -*-
#
# Copyright (c) 2005, Free Geek.
#
# This is free software.  You may use, modify, and/or redistribute this software
# under the terms of the GNU General Public License, version 2 or later.  (See
# http://www.gnu.org/copyleft/gpl.html)
#
# = Synopsis
#
#    RubyTUI is a set of functions that are useful for dealing with
#    the command line interface.
#
# = Authors
#
#    * Michael Granger <ged@FaerieMUD.org>
#    * Martin Chase <stillflame@freegeek.org>
#

# do some setup so we can be usably interactive.
begin
require 'readline'
include Readline
rescue LoadError
#puts "faking readline.."
def readline(prompt)
$stderr.print prompt.chomp
return $stdin.gets.chomp
end
end
require 'timeout'

# Set this to true for ANSI coloration.
$COLOR = true

# Set this to an integer to wrap user input in a timeout.
$TIMEOUT = false

module RubyTUI

    # Set some ANSI escape code constants (Shamelessly stolen from Perl's
    # Term::ANSIColor by Russ Allbery <rra@stanford.edu> and Zenin <zenin@best.com>
    AnsiAttributes = {
        'clear'      => 0,
        'reset'      => 0,
        'bold'       => 1,
        'dark'       => 2,
        'underline'  => 4,
        'underscore' => 4,
        'blink'      => 5,
        'reverse'    => 7,
        'concealed'  => 8,

        'black'      => 30,   'on_black'   => 40, 
        'red'        => 31,   'on_red'     => 41, 
        'green'      => 32,   'on_green'   => 42, 
        'yellow'     => 33,   'on_yellow'  => 43, 
        'blue'       => 34,   'on_blue'    => 44, 
        'magenta'    => 35,   'on_magenta' => 45, 
        'cyan'       => 36,   'on_cyan'    => 46, 
        'white'      => 37,   'on_white'   => 47
    }

    ErasePreviousLine = "\033[A\033[K"

    ###############
    module_function
    ###############

#    DIST=(`uname`.strip == "Darwin" ? "mac" : `lsb_release -cs`.chomp)
    DIST=(`uname`.strip == "Darwin" ? "mac" : "unix")

    # Create a string that contains the ANSI codes specified and return it
    def ansiCode( *attributes )
        return '' unless $COLOR
        return '' unless /(?:vt10[03]|screen|[aex]term(?:-color)?|linux|rxvt(?:-unicode))/i =~ ENV['TERM']
        attr = attributes.collect {|a| AnsiAttributes[a] ? AnsiAttributes[a] : nil}.compact.join(';')
        if attr.empty? 
            return ''
        else
          if DIST != "mac"
            str = "\e[%sm"
          else
            str = "\001\033[%sm\002"
          end
          return str % attr
        end
    end

    ### Return the given +prompt+ with the specified +attributes+ turned on and
    ### a reset at the end.
    def colored( prompt, *attributes )
        return ansiCode( *(attributes.flatten) ) + prompt + ansiCode( 'reset' )
    end

    ### Output <tt>msg</tt> as a ANSI-colored program/section header (white on
    ### blue).
    HeaderColor = [ 'bold', 'white', 'on_blue' ]
    def header( msg )
        msg.chomp!
        $stderr.puts ansiCode( *HeaderColor ) + msg + ansiCode( 'reset' )
        $stderr.flush
    end

    ### Output <tt>msg</tt> as a ANSI-colored highlighted text.
    HighlightColor = [ 'red', 'bold' ]
    def highlight( msg )
        $stderr.print ansiCode( *HighlightColor ) + msg + ansiCode( 'reset' )
        $stderr.flush
    end

    ### Output <tt>msg</tt> to STDERR and flush it.
    MessageColor = [ 'cyan' ]
    def message( msg )
        $stderr.print ansiCode( *MessageColor ) + msg + ansiCode( 'reset' )
        $stderr.flush
    end

    ### Put a newline on the end of a message call.
    def echo( string )
        message string.chomp + "\n"
    end

    ### Output the specified <tt>msg</tt> as an ANSI-colored error message
    ### (white on red).
    ErrorColor = [ 'bold', 'white', 'on_red' ]
    def errorMessage( msg )
        message ansiCode( *ErrorColor ) + msg + ansiCode( 'reset' )
    end

    ### Output the specified <tt>msg</tt> as an ANSI-colored debugging message
    ### (yellow on blue).
    DebugColor = [ 'bold', 'yellow', 'on_blue' ]
    def debugMsg( msg )
        return unless $DEBUG
        msg.chomp!
        $stderr.puts ansiCode( *DebugColor ) + ">>> #{msg}" + ansiCode( 'reset' )
        $stderr.flush
    end

    ### Output the specified <tt>msg</tt> without any colors
    def display( msg )
        $stderr.print msg
        $stderr.flush
    end

    ### Erase the previous line (if supported by your terminal) and output the
    ### specified <tt>msg</tt> instead.
    def replaceMessage( msg )
        print ErasePreviousLine
        message( msg )
    end

    ### Output a divider made up of <tt>length</tt> hyphen characters.
    def divider( length=75 )
        $stderr.puts( "-" * length )
        $stderr.flush
    end
    alias :writeLine :divider

    ### Clear the screen.
    def clear
        $stderr.write `clear`
        $stderr.flush
    end

    ### Provide a pause and prompt to continue.
    def waitasec
        display "\n"
        divider(10)
        pausePrompt
        clear
    end

    ### Wait for input.
    def pausePrompt
        prompt "press ENTER to continue..."
    end

    ### Output the specified <tt>msg</tt> colored in ANSI red and exit with a
    ### status of 1.
    def abort( msg )
        print ansiCode( 'bold', 'red' ) + "Aborted: " + msg.chomp + ansiCode( 'reset' ) + "\n\n"
        Kernel.exit!( 1 )
    end

    ### Output the specified <tt>promptString</tt> as a prompt (in green) and
    ### return the user's input with leading and trailing spaces removed.
    PromptColor = ['bold', 'green']
    def promptResponse(promptString)
        return readline( ansiCode(*PromptColor) +
            "#{promptString}: " + ansiCode('reset') ).strip
    end

    ### Output the specified <tt>promptString</tt> as a prompt and return the
    ### user's input. If a test is provided, the prompt will repeat until the 
    ### test returns true.  An optional failure message can also be passed in.
    def prompt( promptString, failure_msg="Try again.", &test )
        promptString.chomp!
        response = ""
        if $TIMEOUT
            begin
                Timeout::timeout($TIMEOUT) {
                    response = promptResponse(promptString) 
                }
            rescue Timeout::Error
                errorMessage "\nTimed out!\n"
            end
        else
            response = promptResponse(promptString) 
        end
        until test.call(response)
            errorMessage(failure_msg)
            message("\n")
            response = prompt( promptString )
        end if test
        return response
    end

    ### Prompt the user with the given <tt>promptString</tt> via #prompt,
    ### substituting the given <tt>default</tt> if the user doesn't input
    ### anything.  If a test is provided, the prompt will repeat until the test
    ### returns true.  An optional failure message can also be passed in.
    def promptWithDefault( promptString, default, failure_msg="Try again.", &test )
        response = prompt( "%s [%s]" % [ promptString, default ] )
        response = default if response.empty?
        until test.call(response)
            errorMessage(failure_msg)
            message("\n")
            response = promptWithDefault( promptString, default )
        end if test
        return response
    end

    ### Yes/No prompt with default of No.
    def yesNo( promptString )
      yes_or_no(promptString, false)
    end

    ### Yes/No prompt with default of Yes.
    def noYes( promptString )
      yes_or_no(promptString, true)
    end

    def yes_or_no(promptString, default = nil)
      answer = ""
      if !default.nil?
        answer = promptWithDefault( promptString, default ? "yes" : "no",
            "Please enter 'yes' or 'no'" ) {|response|
            response.match( '^[YyNn]' )
        }
      else
        answer = prompt( promptString, "Please enter 'yes' or 'no'" ) {|response|
          response.match( '^[YyNn]' )
        }
      end
      return answer.match( '^[Yy]' )
    end

    ### Display a menu of numeric choices for the <tt>m_items</tt> passed in,
    ### with a title of <tt>head</tt> and a prompt of <tt>ques</tt>.
    def menu( head, ques, *m_items )
        return m_items[0] if m_items.length == 1
        choice = _displayMenu( head, ques, *m_items )
        until choice and (1..(m_items.length)).include?( choice )
            errorMessage "\nPlease enter a number between 1 and #{m_items.length}\n\n"
            choice = _displayMenu( head, ques, *m_items )
        end
        return m_items[choice - 1]
    end

    ### Display a menu of numeric choices for the <tt>m_items</tt>
    ### passed in, with a title of <tt>head</tt> and a prompt of
    ### <tt>ques</tt>. Unlike <tt>menu</tt>, this respects the index
    ### of the <tt>m_items</tt> array.
    def numberedMenu( head, ques, m_items )
      valid_choices = []
      m_items.each_with_index{|x,i|
        valid_choices << i if !x.nil?
      }
      return m_items[valid_choices[0]] if valid_choices.length == 1
      choice = _displayNumberedMenu( head, ques, m_items )
      until valid_choices.include?( choice )
        errorMessage "\nPlease enter a valid choice\n\n"
        choice = _displayNumberedMenu( head, ques, m_items )
      end
      return m_items[choice]
    end

    ### Display a menu of numeric choices for the <tt>m_items</tt> passed in,
    ### with a title of <tt>head</tt>, a prompt of <tt>ques</tt> and a default
    ### value of <tt>default</tt>.
    def menuWithDefault( head, ques, default, *m_items )
        if (m_items - [default, nil]).length == 0
          return default
        end
        choice = _displayMenu( head, ques + " [#{default}]", *m_items )
        return default unless choice
        until (1..(m_items.length)).include?( choice )
            errorMessage "\nPlease enter a number between 1 and #{m_items.length}\n\n"
            choice = _displayMenu( head, ques + " [#{default}]", *m_items )
            return default unless choice
        end
        return m_items[choice - 1]
    end


    ### Display a menu of numeric choices for the <tt>m_items</tt>
    ### passed in, with a title of <tt>head</tt>, a prompt of
    ### <tt>ques</tt> and a default value of <tt>default</tt>. Unlike
    ### <tt>menuWithDefault</tt>, this respects the index of the
    ### <tt>m_items</tt> array.
    def numberedMenuWithDefault( head, ques, default, m_items )
      if (m_items - [default, nil]).length == 0
        return default
      end
      choice = _displayNumberedMenu( head, ques + " [#{default}]", m_items )
      return default unless choice
      valid_choices = []
      m_items.each_with_index{|x,i|
        valid_choices << i if !x.nil?
      }
      until valid_choices.include?( choice )
        errorMessage "\nPlease enter a valid choice\n\n"
        choice = _displayNumberedMenu( head, ques + " [#{default}]", m_items )
        return default unless choice
      end
      return m_items[choice]
    end

    def _displayNumberedMenu( head, ques, m_items )
      header head
      m_items.each_with_index {|item, i|
        if !item.nil?
          highlight "\t%d" % i.to_s
          display ": %s\n" % item
        end
      }
      choice = prompt( ques )
      return choice.empty? ? nil : choice.to_i
    end

    def _displayMenu( head, ques, *m_items )
        header head
        m_items.each_with_index {|item, i|
            highlight "\t%d" % (i+1).to_s
            display ": %s\n" % item
        }
        choice = prompt( ques )
        return choice.empty? ? nil : choice.to_i
    end
    private :_displayMenu

end # module RubyTUI

#include RubyTUI
