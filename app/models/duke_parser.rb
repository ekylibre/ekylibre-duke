module Duke
  class DukeParser < DukeArticle

    attr_accessor :matching_item, :matching_list, :level, :index, :combo, :attributes, :partial_level

    def initialize(word_combo:, level:, **args) 
      @matching_item = nil 
      @matching_list = nil 
      @indexes = word_combo.first 
      @combo = word_combo.last
      @level = level
      @partial_level = 95
      args.each{|k, v| instance_variable_set("@#{k}", v)}
    end 

    # @parse * for a given word-combo
    def parse
      @attributes.map{|k, val| [k, val[:iterator], val[:list], val[:name_attribute]]}.each do |type, iterator, list, name_attr|
        iterator.each do |item| # iterate over every Item from given iterator
          compare_elements(item.name.split.first, item.id, list) if type.to_sym == :doer # Check first name worker
          compare_elements(item.send(name_attr), item.id, list) # Check given name_attr for *
        end 
      end
      @matching_list.add_to_recognized(@matching_item, @attributes.map{|k, val| val[:list]}) if @matching_item.present?
    end 

    # @param [String] nstr : String we'll compare to @combo 
    # @param [Integer] key : nstr Item key
    # @param [Array] append_list : Correct DukeMatchingArray to append if nstr matches
    def compare_elements(nstr, key, append_list)
      if nstr.present? and @level != 1
        if (distance = @combo.similar(nstr.duke_clear)) > @level||(par_dist = @combo.partial_similar(nstr.duke_clear)) > @partial_level
          (@level = distance; par_dist = nil) if distance > level 
          @partial_level = par_dist if par_dist
          @matching_item = DukeMatchingItem.new(key: key, name: nstr, indexes: @indexes, distance: distance, matched: @combo, par_dist: par_dist)
          @matching_list = append_list
        end
      end 
    end

  end 
end 