module Duke
  class DukeMatchingArray < Array

    def initialize(arr: nil)
      super()
      arr.each{|item| self.push(DukeMatchingItem.new(hash: item))} unless arr.nil?
    end

    #  @param [DukeMatchingArray] arr
    #  @returns concatenated DukeMatchingArray
    def uniq_concat(arr)
      arr.each{|item| self.push(item) unless self.duplicate?(item)}
      self
    end

    #  Ensures unicity by key for DukeMatchingItem
    def uniq_by_key
      self.uniq{|it| it[:key]}
    end

    #  Uniq by key or duplicate allowed if this item is ambiguous
    #  @param [Array of DukeAmbiguity] ambiguities
    def uniq_allow_ambiguity(ambiguities)
      self.select{|itm| self.uniq_by_key.include?(itm) or ambiguities.any?{|amb| amb.first[:description][:key] == itm.key}}
    end

    #  Remove first occurence of an item in the array
    # @param [DukeMatchingItem] itm
    def delete_one(itm)
      self.delete_at(self.index(itm))
    end

    #  Returns element with highest distance
    def max
      self.max_by(&:distance)
    end

    # @returns Array as json
    def as_json(*args)
      self
    end

    # @returns Item by key
    def find_by_key(key)
      self.find{|hash| hash.key == key}
    end

    #  @param [DukeMatchingItem] itm
    #  @param [Array] all_lists, Array of all DukeMatchingArrays
    #  @returns nil, (don't) push itm to self
    def add_to_recognized(itm, all_lists)
      if all_lists.none? {|list| (list.duplicate?(itm) || list.overlap?(itm))} # If no overlap or duplicate, we append
        self.push(itm)
      elsif all_lists.none? {|list| list.lower_overlap? itm} # If overlap with lower distance, we append
        self.push(itm) unless self.duplicate?(itm)
      end
    end

    #  Is there an element inside with same key, can mutate list if duplicate present with lower distance
    #  @param [DukeMatchingItem] itm
    def duplicate?(itm)
      if self.none? {|present_item| present_item.key == itm.key}
        false
      elsif self.none? {|present_item| (present_item.key == itm.key) && present_item.lower_match?(itm)}
        true
      else
        self.delete(self.find {|present_item| present_item[:key] == itm[:key]})
        false
      end
    end

    # Is there an element inside with ovelaps with itm
    #  @param [DukeMatchingItem] itm
    def overlap?(itm)
      self.any?{|present_item| (present_item.indexes & itm.indexes).present?}
    end

    #  @returns [Boolean], overlap with lower distance
    def lower_overlap?(itm)
      overlap = self.find{|present_item| (present_item.indexes & itm.indexes).present?}
      if overlap.nil?
        false
      elsif overlap.distance < itm.distance
        self.delete(overlap)
        false
      else
        true
      end
    end

  end
end
