#!/usr/bin/ruby -wd

require 'lib/rubytui'


choice = menu( "Please choose a foo:", "Which foo?",
	"foo", "bar", "my mother is a cat" )

debugMsg "your choice was '#{choice}'\n\n"


choice = menuWithDefault( "Please choose a foo", "Which foo?", "bar",
	"foo", "bar", "my mother is a cat" )

debugMsg "your choice was '#{choice}'"
