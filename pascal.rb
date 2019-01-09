#!/usr/bin/env ruby

class PascalRow
  FIRST_PREVIOUS_ROW_ARY = [].freeze
  FIRST_ROW_ARY = [1].freeze
  EVERY_SIDE_ROW_ARY = [0].freeze
  DEFAULT_MAX_ROWS = 10.freeze

  LEFT_LEANING = true

  def self.print(n_rows=10, max_padding=nil, options={})
    calculated_padding = calculate_padding(n_rows)
    max_padding ||= calculated_padding

    row = new(FIRST_PREVIOUS_ROW_ARY, options)
    (0..n_rows).each do |idx|
      row.print(idx, n_rows, max_padding)
      row = row.next_row # we don't print the very last row ...which is one more than `n_rows`
    end
  end

  attr_reader :idx
  def initialize(previous_row_ary=FIRST_PREVIOUS_ROW_ARY, options={})
    @previous_row_ary = previous_row_ary
    @idx = options[:idx]
  end

  def next_row
    return PascalRow.new(row_ary, idx: (idx ? idx + 1 : nil)) # avoid mutation, create a new one...
  end

  def print(idx=nil, max_id=nil, max_padding=nil)
    print_row(self, idx || @idx, max_id, max_padding)
  end

  def padding(cached_padding_value=nil)
    PascalRow.padding_for_row_ary(row_ary, cached_padding_value)
  end

  private

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
    return starting_ary.each_cons(2).map {|a,b| a + b }
  end

  def print_row(row, idx=nil, max_id=nil, max_padding=nil)
    PascalRow.print_row_ary(row.send(:row_ary), idx || row.idx, max_id, max_padding)
  end

  def self.print_row_ary(row_ary, idx=nil, max_id=nil, max_padding=nil)
    ret_str = row_ary.inspect.to_s.sub('[',"0, ").sub(']', ", 0\n")

    if idx
      padding = padding_for_row_ary(row_ary, max_padding) # FYI: this method recalculates ret_str
      if max_id
        if LEFT_LEANING # I really just need to make a grid, and align each value in each cell
          custom_padding = padding - (max_id - idx) # left side aligned
        else
          custom_padding = padding
        end

        ret_str = sprintf("%#{max_id.to_s.length - idx.to_s.length + 1}s:%#{custom_padding}s" % [idx, ret_str])
      else
        ret_str = sprintf("%d:%#{padding}s" % [idx, ret_str])
      end
    end

    puts ret_str
  end

  def self.calculate_padding(n_rows=nil)
    max_padding = 0
    row = new(FIRST_PREVIOUS_ROW_ARY, idx: 0)
    (0..n_rows).each do |idx|
      max_padding = row.padding
      row = row.next_row
    end
    return max_padding
  end

  # unused:
  def previous_row
    # no rows prior to the first row:
    return nil if [FIRST_PREVIOUS_ROW_ARY].include?(@previous_row_ary)

    # This code is slow but sufficient since I'm never going to calculate a million rows: start at beginning (0) and search till we find the current row... then backup-one
    # (alternatively we sum the cell-values in this row, then determine what power-of-2 that is, at which point we'll know row-number (aka: 'n') such that we can calculate: n-choose-k)
    potential_row = PascalRow.new(FIRST_ROW_ARY, idx: 0) # avoid mutation, just create a new one...
    while potential_row.row_ary == @previous_row_ary
      potential_row = potential_row.next_row
    end
    potential_row
  end

  # unused:
  def print_next(idx=nil)
    next_row.print(idx)
  end

  # unused:
  def print_previous(idx=nil, max_id=nil, max_padding=nil)
    PascalRow.print_row_ary(@previous_row_ary, idx || (@idx ? @idx - 1 : nil), max_id, max_padding)
  end

  def self.padding_for_row_ary(row_ary, cached_padding_value=nil)
    row_ary_str = row_ary.inspect.to_s.sub('[',"0, ").sub(']', ", 0\n")
    len = 1
    if cached_padding_value
      len = cached_padding_value
    else
      string_to_pad = ": #{row_ary_str}"
      len = string_to_pad.length
      # warn "str (of #{len} chars) to pad: #{string_to_pad}"
    end
    return len
  end
end

if __FILE__ == $PROGRAM_NAME
  require "optparse"
  options = {}
  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: ruby #{$0} [OPTIONS]..."

    # BEGIN FORMATTING HACKS:
    # FIXME: add option to calculate spacing based on a full-grid ...will likely need to account for missing 0's to do so...
    opts.on("-m [MAX_PADDING]", "--max_padding [MAX_PADDING]", "Padding required for longest line of triangle -- in order to center output") do |m|
      options[:max_padding] = m.to_i
    end
    # END FORMATTING HACKS:

    opts.on("-r [ROW_NUM]", "--row_num [ROW_NUM]", "Row Number") do |r|
      options[:row_num] = r.to_i
    end

    opts.on("-a [ROW_ARY]", "--row_ary [ROW_ARY]", "Row Ary") do |a|
      options[:row_ary] = a ? a.split(/,\s*/) : []
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

  if options[:row_ary]
    row_ary = options.delete(:row_ary).map(&:to_i)
    row_ary = PascalRow::FIRST_ROW_ARY unless row_ary.size > 0
    warn "Using Pascal's formula on #{row_ary.inspect} would yield:"
    pr = PascalRow.new(row_ary, options)
    pr.print(options[:num_rows_to_print])
  elsif options[:row_num]
    pr = PascalRow.new(PascalRow::FIRST_PREVIOUS_ROW_ARY, options.merge({idx: 0}))
    warn "Retrieving row ##{options[:row_num]}..."
    while pr.idx < options[:row_num]
      pr = pr.next_row
    end
    pr.print
  else
    max_padding = options[:max_padding]
    num_rows_to_print = options[:num_rows_to_print] || 10
    warn "Printing the first #{num_rows_to_print} row(s) of Pascal's triangle..."
    PascalRow.print(num_rows_to_print, max_padding, options)
  end
end
