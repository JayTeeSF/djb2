#!/usr/bin/env ruby

# Thx to: http://www.cse.yorku.ca/~oz/hash.html

class Djb2
  DEFAULT_HASH_VALUE = 5381.freeze

  # this algorithm (k=33) was first reported by dan bernstein many years ago in comp.lang.c.
  # another version of this algorithm (now favored by bernstein) uses
  # xor: hash(i) = hash(i - 1) * 33 ^ str[i];
  # the magic of number 33 (why it works better than many other constants, prime or not)
  # has never been adequately explained.
  def hash(input_str)
    hash = DEFAULT_HASH_VALUE
    input_str.split(//).each do |c|
      hash = ((hash << 5) + hash) + c.ord # hash * 33 + c:
    end
    return hash
  end
end

if __FILE__ == $PROGRAM_NAME
	hash_fn = Djb2.new
  input_str = ARGV.join(' ') if ARGV.size > 0
	unless input_str
	  input_str = "this is a test string that we are using"
	  warn <<-EOH
      #{$0} <string to hash*>

      *Note: using: '#{input_str}'
	  EOH
	end
  result = hash_fn.hash(input_str)
	puts result
end
