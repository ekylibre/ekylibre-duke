module Duke
  module Models
    class DukeMatchingArray < Array

      attr_accessor :date, :duration, :user_input

      def initialize 
        super()
      end 

      def as_json() 
        self
      end 

      def add_to_recognized(new_mItem, all_lists)
        byebug
        #Function that adds elements to a list of recognized items only if no other elements uses the same words to match or if this word has a lower fuzzmatch
        #If no element inside any of the lists has the same words used to match an element (overlapping indexes), and no duplicate => we push the hash to the list
        if not all_lists.any? {|aList| aList.any_overlap_or_duplicate? new_mItem}
          self.push(new_mItem)
        # Else if one or multiple elements uses the same words -> if the distance is greater for this hash -> Remove other ones and add this one
        elsif not all_lists.any? {|aList| aList.any_overlap_and_lower}
          # Check for duplicates in the list, if clear : -> remove value from any list with indexes overlapping and add current match to our list
          unless self.key_duplicate?(new_mItem)
            all_lists.find{|aList| aList.has_overlapping(new_mItem)}.delete_overlapping(new_mItem.indexes)
            self.push(new_mItem)
          end
        end
      end

      def any_duplicate?(new_mItem)
        # Is there a duplicate in the list ? + List we want to keep using. List Mutation allows us to persist modification
        # ie. No Duplicate -> false + current list, Duplicate -> Distance(+/-)=False/True + Current list (with/without duplicate)
        return false if not self.any? {|mItem| mItem.key == new_mItem.key}
        return true if not self.any? {|mItem| mItem.key == new_mItem.key and mItem.has_lower_match?(new_mItem)}
        self.delete(self.find {|mItem| mItem[:key] == new_mItem[:key]})
        return false
      end

      def any_overlap?(itm)
        return self.any?{|mItem| (mItem.indexes & itm.indexes).present?}
      end 

      def any_overlap_or_duplicate? itm
        return true if self.any_duplicate? itm
        return (true if self.any_overlap? itm)||false
      end 

      def any_overlap_and_lower? itm
        overlap = self.find{|mItem| (mItem.indexes & itm.indexes).present?}
        return false if overlap.nil? 
        return (true if overlap.has_lower_match? itm)||false
      end 

      def delete_overlapping itm
        to_rem = self.find{|mItem| (mItem.indexes & itm.indexes).present? }
        self.delete(to_rem) unless to_rem.blank?
      end 

      def uniq_concat(mArr)
        # Concatenate two "recognized items" arrays, by making sure there's not 2 values with the same key
        mArr.each{|mItem| self.push(mItem) unless self.any_duplicate?(mItem)}
        self
      end

    end 
  end 
end 