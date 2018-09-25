#!/usr/bin/env ruby

class PascalRow
  FIRST_PREVIOUS_ROW_ARY = [].freeze
  FIRST_ROW_ARY = [1].freeze
  EVERY_SIDE_ROW_ARY = [0].freeze

  def self.print(n=10, max_row=nil)
    max_row ||= n
    row = new(FIRST_PREVIOUS_ROW_ARY)
    (0..n).to_a.each do |idx|
      row.print(idx, max_row)
      row = row.next_row
    end
  end

  attr_reader :previous_row_ary, :idx
  def initialize(previous_row_ary=FIRST_PREVIOUS_ROW_ARY, idx=nil)
    @previous_row_ary = previous_row_ary
    @idx = idx
  end

  def previous_row
    # no rows prior to the first row:
    return nil if [FIRST_PREVIOUS_ROW_ARY].include?(previous_row_ary)

    idx = 0
    # slow but effective (alternatively we sum the row, determine the power of 2, then we'll know row-number (aka: 'n') so we can do: n-choose-k)
    potential_row = PascalRow.new(FIRST_ROW_ARY, idx)

    while potential_row.row_ary == previous_row_ary
      potential_row = potential_row.next_row
    end
    potential_row
  end

  def next_row
    return PascalRow.new(row_ary, idx ? idx + 1 : nil)
  end

  def print(idx=nil, max_row=nil)
    print_row(self, idx || @idx, max_row)
  end

  def print_next(idx=nil)
    next_row.print(idx)
  end

  def print_previous(idx=nil, max_row=nil)
    print_row_ary(previous_row_ary, idx || (@idx ? @idx - 1 : nil), max_row)
  end

  private

  def row_ary
    return FIRST_ROW_ARY if FIRST_PREVIOUS_ROW_ARY == previous_row_ary

    starting_ary = EVERY_SIDE_ROW_ARY + previous_row_ary + EVERY_SIDE_ROW_ARY
    # warn "starting_ary: #{starting_ary.inspect}"
    # (EVERY_SIDE_ROW_ARY + row).zip(row + EVERY_SIDE_ROW_ARY).map {|(a,b)| a + b }
    return starting_ary.each_cons(2).map {|a,b| a + b }
  end

  def print_row(row, idx=nil, max_row=nil)
    print_row_ary(row.send(:row_ary), idx || row.idx, max_row)
  end

  # ten_to_nineteen       =  38..107
  # twenty_to_twenty_nine = 116..224
  # thirty_to_thirty_nine = 238..381

  DEFAULT_MAX_ROWS = 10.freeze
  def print_row_ary(row_ary, idx=nil, max_row=nil)
    if idx
      # warn "max_row: #{max_row}"
      max_row ||= [idx, DEFAULT_MAX_ROWS].max

      # can't account for the # of digits per number!
      padding = ( (row_ary.inspect.length) / 2 ) + "#{idx}: ".length
      padding += max_row * 2

      # warn "row[#{idx}]-padding: #{padding.inspect}"
      puts "%d:%#{padding}s" % [idx, row_ary.inspect]
    else
      puts row_ary.inspect
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  previous_row = ARGV
  if 1 == previous_row.size && 1 != previous_row[0]
    num_rows_to_print = ARGV[0].to_i
    PascalRow.print(num_rows_to_print, num_rows_to_print)
  else
    PascalRow.new(previous_row.map(&:to_i)).print
  end
end
