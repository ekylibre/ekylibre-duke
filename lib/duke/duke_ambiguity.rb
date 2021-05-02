module Duke
  class DukeAmbiguity < Array
    include Duke::Utils::BaseDuke
    using Duke::Utils::DukeRefinements

    # Creates ambiguity item
    def initialize(itm:, ambiguity_attr:, itm_type:)
      super()
      @ambig_level = 10
      @options = []
      @itm = itm
      @attributes = ambiguity_attr
      @itm_type = itm_type
    end

    # checks every @attribute.type for ambiguous items
    # @return self as an array
    def check_ambiguity
      @attributes.each do |type, iterator|
        iterator.each do |product|
          @options.push(option(product: product, type: type)) if ambiguous?(product)
        end
      end
      create_ambiguity
    end

    private

      attr_reader :options, :itm, :ambig_level, :itm_type

      # @param [ActiveRecord] product
      # @return bln, check if product is ambiguous with self
      def ambiguous?(product)
        @itm.key != product[:id] && (@itm.distance - @itm.matched.partial_similar(product[:partials])).between?(0, @ambig_level)
      end

      # @param [ActiveRecord] product
      # @return product/self as a json option
      def option(product: nil, type: nil)
        return optionify(@itm.name, "{:type => \"#{@itm_type}\", :key => #{@itm.key}, :name => \"#{@itm.name}\"}") if product.nil?

        return optionify(product[:name], "{:type => \"#{type}\", :key => #{product[:id]}, :name => \"#{product[:name]}\"}")
      end

      # Creates ambiguity item if any ambiguity options are present
      # @return self as an array
      def create_ambiguity
        if @options.present?
          @options.push(option)
          description = { itm_type: @itm_type, key: @itm.key }
          sentence = I18n.t('duke.ambiguities.ask', item: @itm.matched)
          add_target_labels if %i[cultivation crop_groups plant land_parcel].include? @itm_type.to_sym
          self.push(dynamic_options(sentence, @options, description).first)
        end
        self.to_a
      end

      # Sorts @option by target types, and add a "global_label" before each target types
      def add_target_labels
        @options = @options.sort_by{|opt| option_target_type(opt)}
        @options.map.with_index{|opt, ix| { label: option_target_type(opt), idx: ix }}
                .uniq{|res| res[:label]}
                .each_with_index do |res, idx|
          @options.insert(res[:idx] + idx, { global_label: I18n.t("duke.interventions.#{res[:label]}") })
        end
      end

      # @return [String] Target type for an option
      def option_target_type(opt)
        return eval(opt[:value][:input][:text])[:type] if eval(opt[:value][:input][:text])[:type] != 'cultivation'

        Product.find_by_id(eval(opt[:value][:input][:text])[:key]).type
      end

  end
end
