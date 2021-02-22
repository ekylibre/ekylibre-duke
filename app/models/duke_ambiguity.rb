module Duke
  class DukeAmbiguity < Array
    include Duke::BaseDuke

    attr_accessor :options, :name_attr, :itm, :ambig_level, :type, :itm_type

    def initialize(itm:, ambiguity_attr:, itm_type:) 
      super()
      @ambig_level = 10
      @options = []
      @itm = itm 
      @attributes = ambiguity_attr
      @itm_type = itm_type
    end 

    # @param [ActiveRecord] product
    # @return bln, check if product is ambiguous with self
    def is_ambiguous?(product)
      return true if (@itm.key != product.id && ((@itm.distance - @itm.matched.partial_similar(product.send(@name_attr).duke_clear)).between?(0, @ambig_level)))
      return false
    end 

    # @param [ActiveRecord] product
    # @return product/self as a json option
    def amb_option(product: nil)
      return optJsonify(@itm.name, "{:type => \"#{@itm_type}\", :key => #{@itm.key}, :name => \"#{@itm.name}\"}") if product.nil?
      return optJsonify(product.name, "{:type => \"#{@type}\", :key => #{product.id}, :name => \"#{product.name}\"}")
    end 

    # Creates ambiguity item if any ambiguity options are present
    # @return self as an array
    def push_amb 
      if @options.present?
        @options.push(amb_option)
        optDescription = {itm_type: @itm_type, key: @itm.key}
        optSentence = I18n.t("duke.ambiguities.ask", item: @itm.matched)
        add_target_labels if [:cultivation, :crop_groups, :plant, :land_parcel].include? @itm_type.to_sym
        self.push(dynamic_options(optSentence, @options, optDescription).first)
        @options = []
      end
      self.to_a
    end 

    # checks every @attribute.type for ambiguous items
    # @return self as an array 
    def check_ambiguity
      @attributes.each do |type, iterator, name_attr|
        @name_attr = name_attr
        @type = type
        iterator.each do |product|
          @options.push(amb_option(product: product)) if is_ambiguous?(product)
        end
      end
      return push_amb 
    end 

    # Sorts @option by target types, and add a "global_label" before each target types
    # TODO: Do it cleanly ???
    def add_target_labels 
      @options = @options.sort_by{|opt| (eval(opt[:value][:input][:text])[:type] if eval(opt[:value][:input][:text])[:type] != "cultivation")||Product.find_by_id(eval(opt[:value][:input][:text])[:key]).type}
      @options.map.with_index{|opt, ix| {label: (eval(opt[:value][:input][:text])[:type] if eval(opt[:value][:input][:text])[:type] != "cultivation")||Product.find_by_id(eval(opt[:value][:input][:text])[:key]).type, idx: ix}}.uniq{|res| res[:label]}.each_with_index do |res, idx| 
        @options.insert(res[:idx] + idx, {global_label: I18n.t("duke.interventions.#{res[:label]}")})
      end 
    end 

  end 
end 