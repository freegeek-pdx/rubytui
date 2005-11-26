#!/usr/bin/ruby -w
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
BEGIN {
    begin
        require 'readline'
        include Readline
    rescue LoadError => e
        $stderr.puts "Faking readline..."
        def readline( prompt )
            $stderr.print prompt.chomp
            return $stdin.gets.chomp
        end
    end
}

$COLOR = true

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

    # Create a string that contains the ANSI codes specified and return it
    def ansiCode( *attributes )
        return '' unless $COLOR
        return '' unless /(?:vt10[03]|screen|[aex]term(?:-color)?|linux)/i =~ ENV['TERM']
        attr = attributes.collect {|a| AnsiAttributes[a] ? AnsiAttributes[a] : nil}.compact.join(';')
        if attr.empty? 
            return ''
        else
            return "\e[%sm" % attr
        end
    end

    ### Return the given +prompt+ with the specified +attributes+ turned on and
    ### a reset at the end.
    def colored( prompt, *attributes )
        return ansiCode( *(attributes.flatten) ) + prompt + ansiCode( 'reset' )
    end

    ### Output <tt>msg</tt> as a ANSI-colored program/section header (white on
    ### blue).
    def header( msg )
        msg.chomp!
        $stderr.puts ansiCode( 'bold', 'white', 'on_blue' ) + msg + ansiCode( 'reset' )
        $stderr.flush
    end

    ### Output <tt>msg</tt> to STDERR and flush it.
    def message( msg )
        $stderr.print ansiCode( 'cyan' ) + msg + ansiCode( 'reset' )
        $stderr.flush
    end

    ### Output the specified <tt>msg</tt> as an ANSI-colored error message
    ### (white on red).
    def errorMessage( msg )
        message ansiCode( 'bold', 'white', 'on_red' ) + msg + ansiCode( 'reset' )
    end

    ### Output the specified <tt>msg</tt> as an ANSI-colored debugging message
    ### (yellow on blue).
    def debugMsg( msg )
        return unless $DEBUG
        msg.chomp!
        $stderr.puts ansiCode( 'bold', 'yellow', 'on_blue' ) + ">>> #{msg}" + ansiCode( 'reset' )
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
        puts "\r" + ("-" * length )
    end
    alias :writeLine :divider

    ### Output the specified <tt>msg</tt> colored in ANSI red and exit with a
    ### status of 1.
    def abort( msg )
        print ansiCode( 'bold', 'red' ) + "Aborted: " + msg.chomp + ansiCode( 'reset' ) + "\n\n"
        Kernel.exit!( 1 )
    end

    ### Output the specified <tt>promptString</tt> as a prompt (in green) and
    ### return the user's input with leading and trailing spaces removed.  If a
    ### test is provided, the prompt will repeat until the test returns true.
    ### An optional failure message can also be passed in.
    def prompt( promptString, failure_msg="Try again.", &test )
        promptString.chomp!
        response = readline( ansiCode('bold', 'green') +
            "#{promptString}: " + ansiCode('reset') ).strip
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
            errorMessage(faiure_msg)
            message("\n")
            response = promptWithDefault( promptString, default )
        end if test
        return response
    end

    # Yes/No prompt with default of No.
    def yesNo( promptString )
        answer = promptWithDefault( promptString, "no",
            "Please enter 'yes' or 'no'" ) {|response|
            response.match( '^[YyNn]' )
        }
        return answer.match( '^[Yy]' )
    end

    # Yes/No prompt with default of Yes.
    def noYes( promptString )
        answer = promptWithDefault( promptString, "yes",
            "Please enter 'yes' or 'no'" ) {|response|
            response.match( '^[YyNn]' )
        }
        return answer.match( '^[Yy]' )
    end

end # module RubyTUI

include RubyTUI
