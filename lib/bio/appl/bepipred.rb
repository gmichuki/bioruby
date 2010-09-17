#
# = bio/appl/bepipred.rb - Bepipred wrapper
# 
# Copyright::   Copyright (C) 2010 
#               George Githinji <georgkam@gmail.com>
# License::     The Ruby License
#
# $Id:$
#
##############################################################################
#   BepiPred predicts the location of linear B-cell epitopes in proteins using
#   a combination of a hidden Markov  model and a propensity scale method. The
#   method is described in the following article:
#
#   Improved method for predicting linear B-cell epitopes.
#   Jens Erik Pontoppidan Larsen, Ole Lund and Morten Nielsen
#   Immunome Research 2:2, 2006.
require 'rubygems'
require 'bio'
require 'bio/command'
require 'shellwords'

module Bio

  # == Description
  # 
  # A wrapper for Bepipred linear B-cell epitope prediction program.
  #
  # === Examples
  #
  #   require 'bio'
  #   seq_file = 'test.fasta'
  #  
  #   factory = Bio::Bepipred.new(seq_file)
  #   report = factory.query
  #   report.class # => Bio::Bepipred::Report
  #
class Bepipred
  autoload :Report, 'bio/appl/bepipred/report'
  
  # Creates a new Bepipred execution wrapper object
  def initialize(program='bepipred',score_threshold=0.35,file_name='')
    @program = program
    @score_threshold = score_threshold
    @file_name = file_name
  end
  
  # name of the program ('bepipred' in UNIX/Linux)
  attr_accessor :program

  # options
  attr_accessor :score_threshold
  
  # return the names of the input sequences
  attr_reader :sequence_names
  
  def sequence_names(file)
    sequence_names = []
    Bio::FlatFile.auto(@file) do |f|
      f.each do |entry|
        sequence_names << entry.definition
      end
    end
    sequence_names
  end
  
  # TODO create a list of query sequences
  
  
  #TODO create a commandline as an array cmd
  def make_command
    cmd = [@program,"-t #{@score_threshold}",@file_name ]
  end
  
  #query the file 
  def query(file_name)
    cmd = make_command
    exec_local(cmd)
  end  
  
  # TODO create a parser class for the ouput
  # parse_results
  DATAPARSED = false
  RESULTS = []

  def dummyload()
    return `/home/kaal/work/ruby/bepipred-1.0b/bepipred </home/kaal/work/ruby/bepipred-1.0b/test/Pellequer.fsa`
  end

  def parse(input) 
    input.each do |line| 
      if (line != "" and not line.split[0] =~ /^\#.*/)
        temp = line.split(/\s{2,}/)
        # fix the source and attributes section
        temp[1] = temp[1].gsub!(" epitope", "")
        if (temp[6] =~ /\..*/) 
          temp[6] = nil 
        else
          temp[6] = {'Note' => 'E'}
        end 
        # generate the result
        RESULTS << [temp[0], temp[1], 'epitope', temp[2].to_i, temp[3].to_i, temp[4].to_f, nil, nil, temp[6]]
      end
    end
  end


  def to_gff3()
    # Delayed loading and parsing to limit resource-useage
    if not DATAPARSED
      parse(dummyload())
    end

    container = Bio::GFF::GFF3.new()

    # Find unique sequence identifiers.
    sequence_names = []
    RESULTS.each { |x|
      if (sequence_names[sequence_names.length-1] != x[0])
        sequence_names << x[0]
      end
    }

    # Create sequence regions for each sequence identifier
    sequence_names.each { |seq| 
      subinput = RESULTS.find_all {|rec| rec[0]==seq}
      min = subinput.min_by {|x| x[3]}
      max = subinput.max_by {|x| x[4]}
      container.sequence_regions << Bio::GFF::GFF3::SequenceRegion.new(seq, min[3], max[4])
    }

    # Lets generate the individual records for the GFF3 output
    RESULTS.each { |x|
      container.records << Bio::GFF::GFF3::Record.new(*x)
    }

    return container.to_s()
  end

  
 private
 #executes bepipred when called localy
 #The input is a file name or a path to the file containing protein sequences in fasta format
 #This method does not work
 # There could be a bug in the way the cmd argument is created.
 def exec_local(cmd)
   Bio::Command.query_command(cmd)
 end
    
end  
end
