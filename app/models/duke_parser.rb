module Duke
  class DukeParser < DukeArticle
    using Duke::DukeRefinements

    attr_accessor :matching_item, :matching_list, :level, :index, :combo, :attributes

    def initialize(word_combo:, level:, **args) 
      @matching_item = nil 
      @matching_list = nil 
      @indexes = word_combo.first 
      @combo = word_combo.last
      @level = level
      args.each{|k, v| instance_variable_set("@#{k}", v)}
    end 

    # @parse * for a given word-combo
    def parse
      @attributes.map{|k, val| [k, val[:iterator], val[:list]]}.each do |type, iterator, list|
        iterator.each do |item| # iterate over every Item from given iterator
          compare_elements(item[:alias], item[:id], item[:name], list) # Check record name
        end 
      end
      @matching_list.add_to_recognized(@matching_item, @attributes.map{|k, val| val[:list]}) if @matching_item.present?
    end 

    # @param [String] nstr : String we'll compare to @combo 
    # @param [Integer] key : nstr Item key
    # @param [Array] append_list : Correct DukeMatchingArray to append if nstr matches
    def compare_elements(aliases, key, name, append_list)
      if aliases.present?
        if (distance = @combo.partial_similar(aliases)) > @level
          @level = distance
          @matching_item = DukeMatchingItem.new(key: key, name: name, indexes: @indexes, distance: distance, matched: @combo)
          @matching_list = append_list
        end
      end 
    end

  end 
end 