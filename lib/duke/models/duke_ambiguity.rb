module Duke
  module Models
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

      def is_ambiguous(product)
        return true if (@itm.key != product.id && (@itm.distance - @fuzzloader.getDistance(clear_string(product.send(@name_attr)), @itm.matched)).between?(0,@ambig_level))
        return false
      end 

      def amb_option(product: nil)
        return optJsonify(@itm.name, "{:type => \"#{@itm_type}\", :key => #{@itm.key}, :name => \"#{@itm.name}\"}") if product.nil?
        return optJsonify(product.name, "{:type => \"#{@type}\", :key => #{product.id}, :name => \"#{product.name}\"}")
      end 

      def check_ambiguity
        # Method to check ambiguity about a specific item
        # For each element of the iterator (ex : crop_groups => CropGroup.all ), distances is close (+/-level) to item that matched it's part of the ambiguity possibilities
        @attributes.each do |type, iterator, name_attr|
          @name_attr = name_attr
          @type = type
          iterator.each do |product|
            @options.push(amb_option(product: product)) if is_ambiguous(product)
          end
          # If ambiguous items, we add the current chosen element this ambig, and an element with what_matched do display to the user which words cuased problems
          if @options.present?
            @options.push(amb_option)
            optDescription = {itm_type: @itm_type, key: @itm.key}
            optSentence = I18n.t("duke.ambiguities.ask", item: @itm.matched)
            self.push(dynamic_options(optSentence, @options, optDescription).first)
            @options = []
          end
        end 
        self.to_a
      end 

    end 
  end 
end 