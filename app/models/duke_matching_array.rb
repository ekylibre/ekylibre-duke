module Duke
  class DukeMatchingArray < Array

    attr_accessor :date, :duration, :user_input

    def initialize(arr: nil)
      super()
      arr.each{|item| self.push(DukeMatchingItem.new(hash: item))} unless arr.nil?
    end 

    # @param [DukeMatchingArray] mArr
    # @returns concatenated DukeMatchingArray
    def uniq_concat(mArr)
      mArr.each{|mItem| self.push(mItem) unless self.any_duplicate?(mItem)}
      self
    end

    # Ensures unicity by key for DukeMatchingItem
    def uniq_by_key
      self.uniq{|it|it[:key]}
    end 

    # Returns element with highest distance
    def max 
      return self.max_by{|item| item.distance}
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
        if all_lists.none? {|aList| (aList.duplicate?(itm)||aList.overlap?(itm))} #If no overlap or duplicate, we append
        self.push(itm)
      elsif all_lists.none? {|aList| aList.lower_overlap? itm} #If overlap with lower distance, we append
        self.push(itm) unless self.duplicate?(itm)
      end
    end

    # Is there an element inside with same key, can mutate list if duplicate present with lower distance
    # @param [DukeMatchingItem] itm
    def duplicate? itm
      return false if self.none? {|mItem| mItem.key == itm.key}
      return true if self.none? {|mItem| mItem.key == itm.key and mItem.lower_match?(itm)}
      self.delete(self.find {|mItem| mItem[:key] == itm[:key]})
      return false
    end

    # Is there an element inside with ovelaps with itm 
    # @param [DukeMatchingItem] itm
    def overlap? itm 
      return self.any?{|mItem| (mItem.indexes & itm.indexes).present?}
    end 

    # @returns bln, checks overlap with lower distance
    def lower_overlap? itm
      overlap = self.find{|mItem| (mItem.indexes & itm.indexes).present?}
      return false if overlap.nil? 
      if overlap.distance < itm.distance
        self.delete(overlap)
        return false 
      end 
      return true 
    end 

  end 
end 