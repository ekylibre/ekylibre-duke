module Duke
  module Models
    class DukeParser < DukeArticle

      attr_accessor :matching_item, :matching_list, :level, :index, :combo, :attributes
      attr_reader :fuzzloader

      def initialize(word_combo:, level: 0.89, **args) 
        @fuzzloader = FuzzyStringMatch::JaroWinkler.create( :pure )
        @matching_item = nil 
        @matching_list = nil 
        @indexes = word_combo.first 
        @combo = word_combo.last
        @level = level
        args.each{|k, v| instance_variable_set("@#{k}", v)}
      end 

      def parse
        @attributes.map{|k, val| [k, val[:iterator], val[:list], val[:name_attribute]]}.each do |iType, iTerator, iList, iName_attr|
          iTerator.each do |item|
            compare_elements(item.name.split.first, item.id, iList) if iType.to_sym == :workers # Check first name worker
            compare_elements(item.send(iName_attr), item.id, iList)
          end 
        end
        @matching_list.add_to_recognized(@matching_item, @attributes.map{|k, val| val[:list]}) if @matching_item.present?
      end 

      def compare_elements(nstr, key, append_list)
        # We check the fuzz distance between two elements, it's greater than the min_matching_level or the current best distance, this is the new recordman
        # We only compare with item_part before "|" any delimiter is present
        if nstr.present? and @level != 1
          distance = @fuzzloader.getDistance(@combo, clear_string(nstr))
          if distance > @level
            @level = distance
            @matching_item = Duke::Models::DukeMatchingItem.new(key: key, name: nstr, indexes: @indexes, distance: distance, matched: @combo)
            @matching_list = append_list
          end
        end 
      end

    end 
  end 
end 