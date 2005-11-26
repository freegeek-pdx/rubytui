#!/usr/bin/ruby
#
#       Module Install Script
#       $Id$
#
#       in debian, this script depends on libruby and ruby
#

require 'ftools'
require 'rbconfig'
include Config

sitelibdir = CONFIG['sitelibdir']
libdir = 'lib'
libs = [ 'rubytui.rb' ]

libs.each {|lib|
    srcfile = File.join(libdir, lib)
    dstfile = File.join(sitelibdir, lib)

    begin
        success = File.copy(srcfile, dstfile)
    rescue Exception => e
        success = false
    end

    if( success and File.exists?( dstfile ) and File.cmp( srcfile, dstfile ) )
        $stderr.puts "   install #{srcfile} -> #{dstfile}"
    else
        $stderr.puts "   failure installing #{dstfile}"
    end
}
