module Duke
  class DukeAmbiguity < Array
    include Duke::BaseDuke

    attr_accessor :options, :name_attr, :itm, :ambig_level, :type, :itm_type

    def initialize(itm:, ambiguity_attr:, itm_type:) 
      super()
      @fuzzloader = FuzzyStringMatch::JaroWinkler.create( :pure )
      @ambig_level = 0.05
      @options = []
      @itm = itm 
      @attributes = ambiguity_attr
      @itm_type = itm_type
    end 

    # @param [ActiveRecord] product
    # @return bln, check if product is ambiguous with self
    def is_ambiguous(product)
      return true if (@itm.key != product.id && (@itm.distance - @fuzzloader.getDistance(clear_string(product.send(@name_attr)), @itm.matched)).between?(0,@ambig_level))
      return false
    end 

    # @param [ActiveRecord] product
    # @return product/self as a json option
    def amb_option(product: nil)
      return optJsonify(@itm.name, "{:type => \"#{@itm_type}\", :key => #{@itm.key}, :name => \"#{@itm.name}\"}") if product.nil?
      return optJsonify(product.name, "{:type => \"#{@type}\", :key => #{product.id}, :name => \"#{product.name}\"}")
    end 

    # @Creates ambiguity item if any ambiguity options are present
    # @return self as an array
    def push_amb 
      if @options.present?
        @options.push(amb_option)
        optDescription = {itm_type: @itm_type, key: @itm.key}
        optSentence = I18n.t("duke.ambiguities.ask", item: @itm.matched)
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
          @options.push(amb_option(product: product)) if is_ambiguous(product)
        end
      end
      return push_amb 
    end 

  end 
end 