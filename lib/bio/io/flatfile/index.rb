# 
# bio/io/flatfile/index.rb - OBDA flatfile index 
# 
#   Copyright (C) 2002 GOTO Naohisa <ngoto@gen-info.osaka-u.ac.jp> 
# 
#  This library is free software; you can redistribute it and/or 
#  modify it under the terms of the GNU Lesser General Public 
#  License as published by the Free Software Foundation; either 
#  version 2 of the License, or (at your option) any later version. 
# 
#  This library is distributed in the hope that it will be useful, 
#  but WITHOUT ANY WARRANTY; without even the implied warranty of 
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU 
#  Lesser General Public License for more details. 
# 
#  You should have received a copy of the GNU Lesser General Public 
#  License along with this library; if not, write to the Free Software 
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA 
# 
#  $Id: index.rb,v 1.4 2002/08/28 12:32:24 ng Exp $ 
# 


module Bio
  class FlatFileIndex
    MAGIC_FLAT = 'flat/1'
    MAGIC_BDB = 'BerkeleyDB/1'

    #########################################################
    def self.open(name)
      self.new(name)
    end

    def initialize(name)
      @db = DataBank.open(name)
    end

    def close
      check_closed?
      @db.close
      @db = nil
    end

    def closed?
      if @db then
	false
      else
	true
      end
    end

    def check_closed?
      @db or raise IOError, 'closed databank'
    end
    private :check_closed?

    def search(key)
      check_closed?
      @db.search_all(key)
    end

    def search_namespaces(key, *names)
      check_closed?
      @db.search_namespaces(key, *names)
    end

    def search_primary(key)
      check_closed?
      @db.search_primary(key)
    end

    def include?(key)
      check_closed?
      r = @db.search_all_get_unique_id(key)
      if r.empty? then
	nil
      else
	r
      end
    end

    def include_in_namespaces?(key, *names)
      check_closed?
      r = @db.search_namespaces_get_unique_id(key, *names)
      if r.empty? then
	nil
      else
	r
      end
    end

    def include_in_primary?(key)
      check_closed?
      r = @db.search_primary_get_unique_id(key)
      if r.empty? then
	nil
      else
	r
      end
    end

    def namespaces
      check_closed?
      r = secondary_namespaces
      r.unshift primary_namespace
      r
    end

    def primary_namespace
      check_closed?
      @db.primary.name
    end

    def secondary_namespaces
      check_closed?
      @db.secondary.names
    end

    def check_consistency
      check_closed?
      @db.check_consistency
    end

    def always_check_consistency=(bool)
      @db.always_check=(bool)
    end
    def always_check_consistency(bool)
      @db.always_check
    end

    #########################################################

    class Results < Hash

      def +(a)
	raise 'argument must be Results class' unless a.is_a?(self.class)
	res = self.dup
	res.update(a)
	res
      end

      def *(a)
	raise 'argument must be Results class' unless a.is_a?(self.class)
	res = self.class.new
	a.each_key { |x| res.store(x, a[x]) if self[x] }
	res
      end

      def to_s
	self.values.join
      end

      #alias :each_orig :each
      alias :each :each_value
      #alias :to_a_orig :to_a
      alias :to_a :values

    end #class Results

    #########################################################

    module DEBUG
      @@out = STDERR
      @@flag = nil
      def self.out=(io)
	if io then
	  @@out = io
	  @@out = STDERR if io == true
	  @@flag = true
	else
	  @@out = nil
	  @@flag = nil
	end
	@@out
      end
      def self.out
	@@out
      end
      def self.print(*arg)
	@@flag = true if $DEBUG or $VERBOSE
	@@out.print(*arg) if @@out and @@flag
      end
    end #module DEBUG

    module IOroutines
      def file2hash(fileobj)
	hash = {}
	fileobj.each do |line|
	  line.chomp!
	  a = line.split("\t", 2)
	  hash[a[0]] = a[1]
	end
	hash
      end
      module_function :file2hash
      private :file2hash
    end #module IOroutines

    module Template
      class NameSpace
	def filename
	  # should be redifined in child class
	  raise NotImplementedError, "should be redefined in child class"
	end

	def mapping(filename)
	  # should be redifined in child class
	  raise NotImplementedError, "should be redefined in child class"
	  #Flat_1::FlatMappingFile.new(filename)
	end

	def initialize(dbname, name)
	  @dbname = dbname
	  @name = name.dup
	  @name.freeze
	  @file = mapping(filename)
	end
	attr_reader :dbname, :name, :file

	def search(key)
	  @file.open
	  @file.search(key)
	end

	def close
	  @file.close
	end

	def include?(key)
	  r = search(key)
	  unless r.empty? then
	    key
	  else
	    nil
	  end
	end
      end #class NameSpace
    end #module Template

    class FileID
      def self.new_from_string(str)
	a = str.split("\t", 2)
	a[1] = a[1].to_i if a[1]
	self.new(a[0], a[1])
      end

      def initialize(filename, filesize = nil)
	@filename = filename
	@filesize = filesize
	@io = nil
      end
      attr_reader :filename, :filesize

      def check
	r =  (File.size(@filename) == @filesize)
	DEBUG.print "FileID: File.size(#{@filename.inspect})", (r ? '==' : '!=') , "#{@filesize} ", (r ? ': good!' : ': bad!'), "\n"
	r
      end

      def recalc
	@filesize = File.size(@filename)
      end

      def to_s(i = nil)
	if i then
	  str = "fileid_#{i}\t"
	else
	  str = ''
	end
	str << "#{@filename}\t#{@filesize}"
	str
      end

      def open
	unless @io then
	  DEBUG.print "FileID: open #{@filename}\n"
	  @io = File.open(@filename, 'rb')
	  true
	else
	  nil
	end
      end

      def close
	if @io then
	  DEBUG.print "FileID: close #{@filename}\n"
	  @io.close
	  @io = nil
	  nil
	else
	  true
	end
      end

      def seek(*arg)
	@io.seek(*arg)
      end

      def read(size)
	@io.read(size)
      end

      def get(pos, length)
	open
	seek(pos, IO::SEEK_SET)
	data = read(length)
	close
	data
      end
    end #class FileID

    class FileIDs < Array
      def initialize(prefix, hash)
	@hash = hash
	@prefix = prefix
      end

      def [](n)
	r = super(n)
	if r then
	  r
	else
	  data = @hash["#{@prefix}#{n}"]
	  if data then
	    self[n] = data
	  end
	  super(n)
	end
      end

      def []=(n, data)
	if data.is_a?(FileID) then
	  super(n, data)
	elsif data then
	  super(n, FileID.new_from_string(data))
	else
	  # data is nil
	  super(n, nil)
	end
	self[n]
      end

      def add(*arg)
	arg.each do |filename|
	  self << FileID.new(filename)
	end
      end
      
      def each
	(0...self.size).each do |i|
	  x = self[i]
	  yield(x) if x
	end
	self
      end

      def each_with_index
	(0...self.size).each do |i|
	  x = self[i]
	  yield(x, i) if x
	end
	self
      end

      def check_all
	r = true
	self.each do |x|
	  r = x.check
	  break unless r
	end
	r
      end
      alias :check :check_all

      def close_all
	self.each do |x|
	  x.close
	end
	nil
      end
      alias :close :close_all

      def recalc_all
	self.each do |x|
	  x.recalc
	end
	true
      end
      alias :recalc :recalc_all

    end #class FileIDs

    module Flat_1
      class Record
	def initialize(str, size = nil)
	  a = str.split("\t")
	  a.each { |x| x.to_s.gsub!(/[\000 ]+\z/, '') }
	  @key = a.shift.to_s
	  @val = a
	  @size = (size or str.length)
	  DEBUG.print "key=#{@key.inspect},val=#{@val.inspect},size=#{@size}\n"
	end
	attr_reader :key, :val, :size

	def to_s
	  self.class.to_string(@size, @key, @val)
	end

	def self.to_string(size, key, val)
	  sprintf("%-*s", size, key + "\t" + val.join("\t"))
	end

	def self.create(size, key, val)
	  self.new(self.to_string(size, key, val))
	end
      end #class Record

      class FlatMappingFile
	@@recsize_width = 4
	@@recsize_regex = /\A\d{4}\z/

	def self.open(*arg)
	  self.new(*arg)
	end

	def initialize(filename, mode = 'rb')
	  @filename = filename
	  @mode = mode
	  @file = nil
	  #@file = File.open(filename, mode)
	  @record_size = nil
	  @records = nil
	end
	attr_accessor :mode
	attr_reader :filename
	
	def open
	  unless @file then
	    DEBUG.print "FlatMappingFile: open #{@filename}\n"
	    @file = File.open(@filename, @mode)
	    true
	  else
	    nil
	  end
	end

	def close
	  if @file then
	    DEBUG.print "FlatMappingFile: close #{@filename}\n"
	    @file.close
	    @file = nil
	  end
	  nil
	end

	def record_size
	  unless @record_size then
	    open
	    @file.seek(0, IO::SEEK_SET)
	    s = @file.read(@@recsize_width)
	    raise 'strange record size' unless s =~ @@recsize_regex
	    @record_size = s.to_i
	    DEBUG.print "FlatMappingFile: record_size: #{@record_size}\n"
	  end
	  @record_size
	end

	def get_record(i)
	  rs = record_size
	  seek(i)
	  str = @file.read(rs)
	  DEBUG.print "get_record(#{i})=#{str.inspect}\n"
	  str
	end

	def seek(i)
	  rs = record_size
	  @file.seek(@@recsize_width + rs * i)
	end

	def records
	  unless @records then
	    rs = record_size
	    @records = (@file.stat.size - @@recsize_width) / rs
	    DEBUG.print "FlatMappingFile: records: #{@records}\n"
	  end
	  @records
	end
	alias :size :records

	# methods for writing file
	def write_record(str)
	  rs = record_size
	  rec = sprintf("%-*s", rs, str)[0..rs]
	  @file.write(rec)
	end

	def add_record(str)
	  n = records
	  rs = record_size
	  @file.seek(0, IO::SEEK_END)
	  write_record(str)
	  @records += 1
	end

	def put_record(i, str)
	  n = records
	  rs = record_size
	  if i >= n then
	    @file.seek(0, IO::SEEK_END)
	    @file.write(sprintf("%-*s", rs, '') * (i - n))
	    @records = i + 1
	  else
	    seek(i)
	  end
	  write_record(str)
	end

	def init(rs)
	  unless 0 < rs and rs < 10 ** @@recsize_width then
	    raise 'record size out of range'
	  end
	  open
	  @record_size = rs
	  str = sprintf("%0*d", @@recsize_width, rs)
	  @file.truncate(0)
	  @file.seek(0, IO::SEEK_SET)
	  @file.write(str)
	  @records = 0
	end

	def self.create(record_size, filename, mode = 'wb+')
	  f = self.new(filename, mode)
	  f.init(record_size)
	end

	# methods for searching
	def search(key)
	  n = records
	  return [] if n <= 0
	  i = n / 2
	  i_prev = nil
	  DEBUG.print "binary search starts...\n"
	  begin
	    rec = Record.new(get_record(i))
	    i_prev = i
	    if key < rec.key then
	      n = i
	      i = i / 2
	    elsif key > rec.key then
	      i = (i + n) / 2
	    else # key == rec.key
	      result = [ rec.val ]
	      j = i - 1
	      while j >= 0 and
		  (rec = Record.new(get_record(j))).key == key
		result << rec.val
		j = j - 1
	      end
	      result.reverse!
	      j = i + 1
	      while j < n and
		  (rec = Record.new(get_record(j))).key == key
		result << rec.val
		j = j + 1
	      end
	      DEBUG.print "#{result.size} hits found!!\n"
	      return result
	    end
	  end until i_prev == i
	  DEBUG.print "no hits found\n"
	  #nil
	  []
	end
      end #class FlatMappingFile

      class PrimaryNameSpace < Template::NameSpace
	def mapping(filename)
	  FlatMappingFile.new(filename)
	end
	def filename
	  File.join(dbname, "key_#{name}.key")
	end
      end #class PrimaryNameSpace

      class SecondaryNameSpace < Template::NameSpace
	def mapping(filename)
	  FlatMappingFile.new(filename)
	end
	def filename
	  File.join(dbname, "id_#{name}.index")
	end
	def search(key)
	  r = super(key)
	  file.close
	  r.flatten!
	  r
	end
      end #class SecondaryNameSpace
    end #module Flat_1


    class NameSpaces < Hash
      def initialize(dbname, nsclass, arg)
	@dbname = dbname
	@nsclass = nsclass
	if arg.is_a?(String) then
	  a = arg.split("\t")
	else
	  a = arg
	end
	a.each do |x|
	  self[x] = @nsclass.new(@dbname, x)
	end
	self
      end

      def each_names
	self.names.each do |x|
	  yield x
	end
      end

      def each_files
	self.values.each do |x|
	  yield x
	end
      end

      def names
	keys
      end

      def close_all
	values.each { |x| x.file.close }
      end
      alias :close :close_all

      def search(key)
	r = []
	values.each do |ns|
	  r.concat ns.search(key)
	end
	r.sort!
	r.uniq!
	r
      end

      def search_names(key, *names)
	r = []
	names.each do |x|
	  ns = self[x]
	  raise "undefined namespace #{x}" unless ns
	  r.concat ns.search(key)
	end
	r
      end

      def to_s
	names.join("\t")
      end
    end #class NameSpaces

    class DataBank
      def self.filename(dbname)
	File.join(dbname, 'config.dat')
      end

      def self.read(name, mode = 'rb', *bdbarg)
	f = File.open(filename(name), mode)
	hash = IOroutines::file2hash(f)
	f.close
	db = self.new(name, nil, hash)
	db.bdb_open(*bdbarg)
	db
      end

      def self.open(*arg)
	self.read(*arg)
      end

      def initialize(name, idx_type = nil, hash = {})
	@dbname = name.dup
	@dbname.freeze
	@bdb = nil

	@always_check = true
	self.index_type = (hash['index'] or idx_type)

	if @bdb then
	  @config = BDBwrapper.new(@dbname, 'config')
	  @bdb_fileids = BDBwrapper.new(@dbname, 'fileids')
	  @nsclass_pri = BDB_1::PrimaryNameSpace
	  @nsclass_sec = BDB_1::SecondaryNameSpace
	else
	  @config = hash
	  @nsclass_pri = Flat_1::PrimaryNameSpace
	  @nsclass_sec = Flat_1::SecondaryNameSpace
	end
	true
      end

      attr_reader :dbname, :index_type

      def index_type=(str)
	case str
	when MAGIC_BDB
	  @index_type = MAGIC_BDB
	  @bdb = true
	  unless defined?(BDB)
	    raise RuntimeError, "Berkeley DB support not found"
	  end
	when MAGIC_FLAT, '', nil, false
	  @index_type = MAGIC_FLAT
	  @bdb = false
	else
	  raise 'unknown or unsupported index type'
	end
      end

      def to_s
	a = ""
	a << "index\t#{@index_type}\n"

	unless @bdb then
	  a << "format\t#{@format}\n"
	  @fileids.each_with_index do |x, i|
	    a << "#{x.to_s(i)}\n"
	  end
	  a << "primary_namespace\t#{@primary.name}\n"
	  a << "secondary_namespaces\t"
	  a << @secondary.names.join("\t")
	  a << "\n"
	end
	a
      end

      def bdb_open(*bdbarg)
	if @bdb then
	  @config.close
	  @config.open(*bdbarg)
	  @bdb_fileids.close
	  @bdb_fileids.open(*bdbarg)
	  true
	else
	  nil
	end
      end

      def write(mode = 'wb', *bdbarg)
	unless FileTest.directory?(@dbname) then
	  Dir.mkdir(@dbname)
	end
	f = File.open(self.class.filename(@dbname), mode)
	f.write self.to_s
	f.close

	if @bdb then
	  bdb_open(*bdbarg)
	  @config['format'] = format
	  @config['primary_namespace'] = @primary.name
	  @config['secondary_namespaces'] = @secondary.names.join("\t")
	  @bdb_fileids.writeback_array('', fileids, *bdbarg)
	end
	true
      end

      def close
	DEBUG.print "DataBank: close #{@dbname}\n"
	primary.close
	secondary.close
	fileids.close
	if @bdb then
	  @config.close
	  @bdb_fileids.close
	end
	nil
      end

      ##parameters
      def primary
	unless @primary then
	  self.primary = @config['primary_namespace']
	end
	@primary
      end

      def primary=(pri_name)
	if !pri_name or pri_name.empty? then
	  pri_name = 'UNIQUE'
	end
	@primary = @nsclass_pri.new(@dbname, pri_name)
	@primary
      end

      def secondary
	unless @secondary then
	  self.secondary = @config['secondary_namespaces']
	end
	@secondary
      end

      def secondary=(sec_names)
	if !sec_names then
	  sec_names = []
	end
	@secondary = NameSpaces.new(@dbname, @nsclass_sec, sec_names)
	@secondary
      end

      def format=(str)
	@format = str.to_s.dup
      end

      def format
	unless @format then
	  format = @config['format']
	end
	@format
      end

      def fileids
	unless @fileids then
	  init_fileids
	end
	@fileids
      end

      def init_fileids
	if @bdb then
	  @fileids = FileIDs.new('', @bdb_fileids)
	else
	  @fileids = FileIDs.new('fileid_', @config)
	end
	@fileids
      end

      # high level methods
      def always_check=(bool)
	if bool then
	  @always_check = true
	else
	  @always_check = false
	end
      end
      attr_reader :always_check

      def get_flatfile_data(f, pos, length)
	fi = fileids[f.to_i]
	if @always_check then
	  raise "flatfile #{fi.filename.inspect} may be modified" unless fi.check
	end
	fi.get(pos.to_i, length.to_i)
      end

      def search_all_get_unique_id(key)
	s = secondary.search(key)
	p = primary.include?(key)
	s.push p if p
	s.sort!
	s.uniq!
	s
      end

      def search_primary(*arg)
	r = Results.new
	arg.each do |x|
	  a = primary.search(x)
	  # a is empty or a.size==1 because primary key must be unique
	  r.store(x, get_flatfile_data(*a[0])) unless a.empty?
	end
	r
      end

      def search_all(key)
	s = search_all_get_unique_id(key)
	search_primary(*s)
      end

      def search_primary_get_unique_id(key)
	s = []
	p = primary.include?(key)
	s.push p if p
	s
      end

      def search_namespaces_get_unique_id(key, *names)
	if names.include?(primary.name) then
	  n2 = names.dup
	  n2.delete(primary.name)
	  p = primary.include?(key)
	else
	  n2 = names
	  p = nil
	end
	s = secondary.search_names(key, *n2)
	s.push p if p
	s.sort!
	s.uniq!
	s
      end

      def search_namespaces(key, *names)
	s = search_namespaces_get_unique_id(key, *names)
	search_primary(*s)
      end

      def check_consistency
	fileids.check_all
      end
    end #class DataBank

  end #class FlatFileIndex
end #module Bio
