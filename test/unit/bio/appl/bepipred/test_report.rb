#
# test/unit/bio/appl/bepipred/test_report.rb - Unit test for Bio::Bepipred::Report
#
# Copyright::  Copyright (C) 2010 George Githinji <georgkam@gmail.com> 
# License::    The Ruby License
#

require 'pathname'
load Pathname.new(File.join(File.dirname(__FILE__), ['..'] * 4,
                            'bioruby_test_helper.rb')).cleanpath.to_s
require 'test/unit'
require 'bio/appl/bepipred/report'


