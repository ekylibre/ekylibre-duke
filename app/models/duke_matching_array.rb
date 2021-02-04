module Duke
  class DukeMatchingArray < Array

    attr_accessor :date, :duration, :user_input

    def initialize(arr: nil)
      super()
      arr.each{|item| self.push(DukeMatchingItem.new(hash: item))} unless arr.nil?
    end 

    # @returns Array as json
    def as_json(*args)
      self
    end 

    # @returns Item by key
    def find_by_key(key)
      self.find{|hash| hash.key == key}
    end 

    # @param [DukeMatchingItem] itm 
    # @param [Array] all_lists, Array of all DukeMatchingArrays
    # @returns nil, (don't) push itm to self
    def add_to_recognized(itm, all_lists)
        if all_lists.none? {|aList| aList.any_overlap_or_duplicate? itm} #If no overlap or duplicate, we append
        self.push(itm)
      elsif all_lists.none? {|aList| aList.any_overlap_and_lower? itm} #If overlap with lower distance, we append
        self.push(itm) unless self.any_duplicate?(itm)
      end
    end

    # @param [DukeMatchingItem] itm
    # @returns bln, list mutation on self if duplicate with lower distance
    def any_duplicate? itm
      return false if not self.any? {|mItem| mItem.key == itm.key}
      return true if not self.any? {|mItem| mItem.key == itm.key and mItem.has_lower_match?(itm)}
      self.delete(self.find {|mItem| mItem[:key] == itm[:key]})
      return false
    end

    # @returns bln, checks overlapping matches in self
    def any_overlap?(itm)
      return self.any?{|mItem| (mItem.indexes & itm.indexes).present?}
    end 

    # @returns bln, checks overlap or duplicate in self
    def any_overlap_or_duplicate? itm
      return true if self.any_duplicate? itm
      return (true if self.any_overlap? itm)||false
    end 

    # @returns bln, checks overlap with lower distance
    def any_overlap_and_lower? itm
      overlap = self.find{|mItem| (mItem.indexes & itm.indexes).present?}
      return false if overlap.nil? 
      if overlap.has_lower_match?(itm)
        self.delete(overlap)
        return false 
      end 
      return true 
    end 

    # @param [DukeMatchingArray] mArr
    # @returns concatenated DukeMatchingArray
    def uniq_concat(mArr)
      mArr.each{|mItem| self.push(mItem) unless self.any_duplicate?(mItem)}
      self
    end

    def uniq_by_key
      self.uniq{|it|it[:key]}
    end 

    def max 
      return self.max_by{|item| item.distance}
    end 

  end 
end 