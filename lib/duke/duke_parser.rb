module Duke
  class DukeParser < Skill::DukeArticle
    using Duke::DukeRefinements

    def initialize(word_combo:, level:, **args)
      @matching_item = nil
      @matching_list = nil
      @indexes = word_combo.first
      @combo = word_combo.last
      @level = level
      args.each{|k, v| instance_variable_set("@#{k}", v)}
    end

    #  @parse every attribute for a given word-combo
    def parse
      @attributes.map{|k, val| [k, val[:iterator], val[:list]]}.each do |_type, iterator, list|
        iterator.each do |item| #  iterate over every Item from given iterator
          compare_elements(item[:partials], item[:id], item[:name], list) #  Check record name
        end
      end
      @matching_list.add_to_recognized(@matching_item, @attributes.map{|_k, val| val[:list]}) if @matching_item.present?
    end

    private

      attr_reader :matching_item, :matching_list, :level, :index, :combo, :attributes

      #  @param [String] nstr : String we'll compare to @combo
      #  @param [Integer] key : nstr Item key
      #  @param [Array] append_list : Correct DukeMatchingArray to append if nstr matches
      def compare_elements(partials, key, name, append_list)
        if partials.present?
          if (distance = @combo.partial_similar(partials)) > @level
            @level = distance
            @matching_item = DukeMatchingItem.new(key: key, name: name, indexes: @indexes, distance: distance, matched: @combo)
            @matching_list = append_list
          end
        end
      end

  end
end
