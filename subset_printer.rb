#!/usr/bin/env ruby

require 'set'
class SubsetPrinter
  def self.run(set_or_ary)
    new(set_or_ary).run
  end

  def initialize(set_or_ary)
    @set = set_or_ary.is_a?(Set) ? set_or_ary : Set.new(set_or_ary.to_a)
    @ary = @set.to_a
  end

  EMPTY_SET = [].freeze
  def run(mode=:iterative)
    idx = 0
    send("#{mode}_set_walker", @ary) do |subset|
      if 0 == idx
        print_set(subset, is_leading_comma=false)
      else
        print_set(subset, is_leading_comma=true)
      end
      idx += 1
    end
    warning = ""
    expected_count = 2**(@ary.size)
    if idx != expected_count
      warning = "; expected: #{expected_count}"
    end
    warn "\nDone: #{idx} sets#{warning}."
  end

  private

  def print_set(set, is_leading_comma=true)
    set_to_str = set.inspect.sub(%r{\[}, "{").sub(%r{\]}, "}")

    if is_leading_comma
      print ",\n" + set_to_str
      return
    end
    print set_to_str
  end

  # rotate = ->(ary) {ary[1..-1] << ary[0]}
  # a  = [1,2,3,4,5,6,7,8]
  # got = Set.new
  # a.zip(rotate[a]).each {|ary| got << ary.sort }
  # => [[1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7], [7, 8], [8, 1]]
  # a.zip(rotate[rotate[a]]).each {|ary| got << ary.sort }
  # ...
  # a.zip(rotate[rotate[rotate[a]]]).each {|ary| got << ary }
  # ...
  # a.zip(rotate[rotate[rotate[rotate[a]]]]).each {|ary| got << ary }
  # ...
  # got.size = 28 # and that matches my pascal's triangle row 8, col 2 (for 8 choose 2)
  def rotate(set_ary=[])
    set_ary[1..-1] << set_ary[0]
  end

  def yield?(got, seen)
    #warn "\n\t***got: #{got.inspect}, seen: #{seen.inspect} ***\n"
    record = got.sort # avoid mutating input
    return false if 1 == seen[record]
    seen[record] = 1 # mutate this.
    return true
  end


  # tt for "truth table" ...cuz it reminds me of how I develop truth table
  # opt-1 (in col-1) alternates every other
  # opt-2 (in col-2) alternates every 2-times
  # opt-3 (in col-3) alterates every 4-times
  # etc...
  def tt_set_walker(set_ary, subset=Set.new([]), do_print=true, &block)
    if do_print
      block.call(subset.to_a)
      do_print = false
    end

    if (subset.size >= set_ary.size)
      #warn "subset (#{subset.size}) is bigger (#{set_ary.size})"
      return
    end

    mutable_set_ary = rotate(set_ary)
    entry = mutable_set_ary.last
    tt_set_walker(mutable_set_ary, subset + [entry], true, &block) # chose the first element of the rotated ary

    #warn "try w/ nth item first..."
    mutable_set_ary.pop
    if mutable_set_ary.empty?
      #warn "no more rotations..."
      return
    end
    tt_set_walker(mutable_set_ary, subset, do_print, &block) # the first element is no longer an option
  end

  # from video <-- slower than the tt-walker I thought of!
  def video_set_walker(given_array, &block)
    subset = Array.new(given_array.length)
    video_helper(given_array, subset, 0, &block)
  end

  # recursive helper of video_set_walker
  def video_helper(given_array, subset, i, &block)
    if i == subset.length
      block.call(subset.reject{|e| e.nil? })
    else
      subset[i] = nil
      video_helper(given_array, subset, i+1, &block)
      subset[i] = given_array[i]
      video_helper(given_array, subset, i+1, &block)
    end
  end

end

if __FILE__ == $PROGRAM_NAME
  warn "tt:"
  t0 = Time.now.to_f
  SubsetPrinter.new(ARGV).run(:tt)
  tN = Time.now.to_f
  tt_took = tN - t0

  #warn "video:"
  #t0 = Time.now.to_f
  #SubsetPrinter.new(ARGV).run(:video)
  #tN = Time.now.to_f
  #video_took = tN - t0

  warn "tt took #{tt_took}secs"
  #warn "video took #{video_took}secs"
end
