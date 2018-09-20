# djb2
ruby implementation of djb2 hash algorithm
Thx to: http://www.cse.yorku.ca/~oz/hash.html
I also saw reference to this in a talk about min-hashing (re: a fast hashing algorithm with decent distribution).


```
hash_alg = Djb2.new
hash_alg.hash("some input")
=> 8246924729000332073

# nice algorithm for identifying similar things:
hash_alg.hash("aa")
=> 5863207
hash_alg.hash("ab")
=> 5863208
hash_alg.hash("ac")
=> 5863209
hash_alg.hash("ad")
=> 5863210
```

with respect to min-hashing perhaps you might do something like:
```
irb -r "./djb2.rb"

doc_a = "here is a document that I would like to hash"
doc_b = "this is another document that I would also like to hash"

class MinH
  DEFAULT_HASH_ALG_CLASS = Djb2.freeze
  DEFAULT_SHINGLE_SIZE = 9.freeze

  def initialize(doc, opts=nil)
    opts ||= {}
    @doc = doc
    @hash_alg = opts[:hash_alg] || DEFAULT_HASH_ALG_CLASS.new
    @k = opts[:k] || DEFAULT_SHINGLE_SIZE
  end

  def to_a
    @to_a ||= @doc.split(//)
  end

  def shingles
    @shingles ||= to_a.each_cons(@k).to_a.map {|s| s.join }
  end
  
  # result will to be a number between 0 and 1
  def resemblance(other, mode=:hashes)
    jaccard_numerator(other, mode) / jaccard_denominator(other, mode)
  end
  
  def jaccard_numerator(other, mode=:hashes)
    Float((send(mode) & other.send(mode)).size)
  end
  
  def jaccard_denominator(other, mode=:hashes)
    (send(mode) | other.send(mode)).size
  end
  
  def min_hash
     hashes.first
  end
  
  def hashes
    @hashes ||= shingles.map { |shingle| @hash_alg.hash(shingle) }.sort
  end
end

min_doc_a = MinH.new(doc_a)
min_doc_b = MinH.new(doc_b)

min_doc_a.shingles
min_doc_b.shingles

min_doc_a.jaccard_numerator(min_doc_b, :shingles) # only 20 matching shingles
min_doc_a.jaccard_denominator(min_doc_b, :shingles) # out of 63 total-unique shingles


min_doc_a.hashes
min_doc_b.hashes

if min_doc_a.min_hash == min_doc_b.min_hash
  warn "These docs have the same min-hash, so let's confirm their similarity..."
  min_doc_a.jaccard_numerator(min_doc_b) # only 20 matching hashes (same as shingles) -- faster to compare #'s vs. strings ?!
  min_doc_a.jaccard_denominator(min_doc_b) # out of 63 total-unique hashes

  puts min_doc_a.resemblance(min_doc_b) # 31.7%
  #min_doc_b.resemblance(min_doc_a) # same -- as it should be
end

```
