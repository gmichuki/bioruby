# = sample/demo_bepipred.rb - demonstration of Bio::Bepipred
#
# Copyright::   Copyright (C) 2010 
#               Alan Orth <a.orth@cgiar.org>
# License::     The Ruby License
#
# == Description
#
# Demonstration of Bio::Bepipred
#
# == Requirements
#
# you have to be in lib/bio/appl for this to work  
#
# == Usage
# 
#  $ cd lib/bio/bio
#
#  Run this script as follows.
#
#  $ ruby ../../../sample/demo_bepipred.rb
#

require 'bepipred'

b = Bio::Bepipred.new('')

puts b.class
