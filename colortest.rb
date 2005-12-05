#!/usr/bin/ruby -w

require 'lib/rubytui'

colors = AnsiAttributes.find_all {|name,val|
    val >= 30 and val <= 37
}
bgs = AnsiAttributes.find_all {|name,val|
    val >= 40
}

def display( msg, *colors )
    $stderr.puts colored( msg, *colors )
    $stderr.flush
end

colors.each {|c_name,c_val|
    bgs.each {|bg_name,bg_val|
        display( "available: #{c_name} #{bg_name}", c_name, bg_name )
    }
}

$stderr.puts
$stderr.puts

display( "used for header: #{HeaderColor.join(' ')}", *HeaderColor )
display( "used for highlight: #{HighlightColor.join(' ')}", *HighlightColor )
display( "used for message: #{MessageColor.join(' ')}", *MessageColor )
display( "used for error: #{ErrorColor.join(' ')}", *ErrorColor )
display( "used for debug: #{DebugColor.join(' ')}", *DebugColor )
