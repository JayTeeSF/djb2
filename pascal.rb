#!/usr/bin/env ruby

class PascalRow
  CENTERED               = true
  DEFAULT_MAX_ROWS       = 10.freeze
  EVERY_SIDE_ROW_ARY     = [0].freeze
  FIRST_PREVIOUS_ROW_ARY = [].freeze
  FIRST_ROW_ARY          = [1].freeze

  def self.print(num_rows=nil, options={})
    num_rows              ||= DEFAULT_MAX_ROWS
    options[:idx]         ||= 0
    options[:max_padding] ||= calculate_padding(num_rows)

    row = new(FIRST_PREVIOUS_ROW_ARY, {max_id: options[:idx] + num_rows}.merge(options))
    while row.idx <= num_rows
      row.print
      row = row.next_row # we don't print the very last row ...which is actually `num_rows + 1`
    end
  end

  def self.retrieve_row(row_num, options={})
    pr = PascalRow.new(PascalRow::FIRST_PREVIOUS_ROW_ARY, options)
    while pr.idx < row_num
      pr = pr.next_row
    end
    return pr
  end

  attr_reader :idx
  def initialize(previous_row_ary=FIRST_PREVIOUS_ROW_ARY, options={})
    @idx              = options[:idx]
    @max_id           = options[:max_id]      # feels wrong to include "formatting" concerns as part of the object
    @max_padding      = options[:max_padding] # feels wrong to include "formatting" concerns as part of the object
    @previous_row_ary = previous_row_ary
  end

  def next_row # avoid mutating the current object, create a new one...
    return PascalRow.new(row_ary, idx: (idx ? idx + 1 : nil), max_id: @max_id, max_padding: @max_padding)
  end

  # The real work:
  # sum-up pairs of elements (cell-values) in the row above
  # in order to calculate the current row's elements (cell-values)
  # a     b
  #  \   /
  #    c (= a + b)
  #
  # Note: every row is wrapped in 0's
  # if the parent-row is a, b (as illustrated above)
  # it's really 0, a, b, 0
  # and the next row is actually: 0, 0 + a, a + b, b + 0
  # where "c" is the 2nd to last of those 4 value(s): a + b
  #
  def row_ary
    return FIRST_ROW_ARY if FIRST_PREVIOUS_ROW_ARY == @previous_row_ary

    starting_ary = EVERY_SIDE_ROW_ARY + @previous_row_ary + EVERY_SIDE_ROW_ARY
    # https://apidock.com/ruby/Enumerable/each_cons ...grabs 2 elements per iteration, shifting by only one-element for every iteration after the first
    return starting_ary.each_cons(2).map {|a,b| a + b }
  end

  ## THE BULK of this code is dedicated to "printing"; ridiculous!
  def print
    PascalRow.print_row_ary(row_ary, idx: idx, max_id: @max_id, max_padding: @max_padding)
  end

  def padding(cached_padding_value=nil)
    PascalRow.padding_for_row_ary(row_ary, cached_padding_value)
  end

  private

  # The remaining methods are not actually private, they're (public) class methods
  # I'm putting them at the bottom because they capture details that _should_ be private (if Ruby allowed that)
  def self.print_row_ary(row_ary, options={})
    idx                  = options[:idx]
    max_id               = options[:max_id]
    max_padding          = options[:max_padding]
    ret_str              = row_ary_to_str(row_ary)
    if idx
      padding            = padding_for_row_ary(row_ary, max_padding) # FYI: this method recalculates ret_str
      if max_id
        left_padding     = padding - (max_id - idx) # left side aligned

        if CENTERED
          ret_str        = sprintf("%#{max_id.to_s.length - idx.to_s.length + 1}s:#{ret_str.center(padding)}" % idx)
        else
          ret_str        = sprintf("%#{max_id.to_s.length - idx.to_s.length + 1}s:%#{left_padding}s" % [idx, ret_str])
        end
      else
        if CENTERED
          ret_str        = sprintf("%d:#{ret_str.center(padding)}" % idx)
        else
          ret_str        = sprintf("%d:%#{padding}s" % [idx, ret_str])
        end
      end
    end

    puts ret_str
  end

  def self.calculate_padding(num_rows=nil)
    max_padding   = 0
    row           = new(FIRST_PREVIOUS_ROW_ARY, idx: 0)
    (0..num_rows).each do |idx|
      max_padding = row.padding
      row         = row.next_row
    end
    return max_padding
  end

  def self.row_ary_to_str(row_ary)
    row_ary.inspect.to_s.sub('[',"0, ").sub(']', ", 0\n")
  end

  def self.padding_for_row_ary(row_ary, cached_padding_value=nil)
    if cached_padding_value
      len           = cached_padding_value
    else
      string_to_pad = ": #{row_ary_to_str(row_ary)}"
      len           = string_to_pad.length #; warn "str (of #{len} chars) to pad: #{string_to_pad}"
    end
    return len
  end
end

if __FILE__ == $PROGRAM_NAME
  require "optparse"
  options       = {}
  opt_parser    = OptionParser.new do |opts|
    opts.banner = "Usage: ruby #{$0} [OPTIONS]..."

    opts.on("-m [MAX_PADDING]", "--max_padding [MAX_PADDING]", "FORMATTING-OPTION: specify length of longest line to speed-up calculation") do |m|
      options[:max_padding]       = m.to_i
    end

    opts.on("-r [ROW_NUM]", "--row_num [ROW_NUM]", "Row Number") do |r|
      options[:row_num]           = r.to_i
    end

    opts.on("-a [ROW_ARY]", "--row_ary [ROW_ARY]", "Row Ary") do |a|
      options[:row_ary]           = a ? a.split(/,\s*/).map(&:to_i) : PascalRow::FIRST_ROW_ARY
    end

    opts.on("-n [NUM_ROWS]", "--num_rows [NUM_ROWS]", "Number of Rows To Print") do |n|
      options[:num_rows_to_print] = n.to_i
    end

    opts.on_tail("-h", "--help", "This help screen" ) do
      puts opts

      puts <<-EOHELP

       e.g. #{$0} -n 3
       \t0, 1, 0\n\t0, 1, 1, 0\n\t0, 1, 2, 1, 0\n\t0, 1, 3, 3, 1, 0

       e.g. #{$0} -r 2
       \t0, 1, 3, 3, 1, 0

       e.g. #{$0} -a '1, 2, 1'
       \t0, 1, 3, 3, 1, 0

       passing no options is equivalent to using: -n 10
      EOHELP
      exit
    end
  end
  opt_parser.parse!

  #warn "options: #{options.inspect}"
  num_rows_to_print = options.delete(:num_rows_to_print)
  row_num           = options.delete(:row_num)
  row_ary           = options.delete(:row_ary)
  if row_ary
    pr              = PascalRow.new(row_ary, options)
    warn "Applying Pascal's formula to #{row_ary.inspect} yields:"
    pr.print
  elsif row_num && row_num >= 0
    pr              = PascalRow.retrieve_row(row_num, options.merge({idx: 0}))
    warn "Retrieving row ##{row_num}..."
    pr.print
  else
    num_rows_to_print ||= PascalRow::DEFAULT_MAX_ROWS
    warn "Printing the first #{num_rows_to_print} row(s) of Pascal's triangle..."
    PascalRow.print(num_rows_to_print, options)
  end
end
