module Duke 
  module Utils 
    class Regex 

      def self.afternoon_hour
        /\b(00|[0-9]|1[0-1]) *(h|heure(s)?|:) *([0-5]?[0-9])?\b *(du|de|cet|cette)? *(le|l')? *(aprem|apm|après-midi|apres midi|après midi|aprèm)/
      end

      def self.hour_interval
        /((de|à|a|entre) *\b((00|[0-9]|1[0-9]|2[0-3]) *(h|heure(s)?|:) *([0-5]?[0-9])?\b|midi|minuit) *(jusqu\')?(a|à|et) *\b((00|[0-9]|1[0-9]|2[0-3]) *(h|heure(s)?|:) *([0-5]?[0-9])?\b|midi|minuit))/
      end

      def self.input_quantity(matched)
        /(\d{1,3}(\.|,)\d{1,2}|\d{1,3}) *((g|gramme|kg|kilo|kilogramme|tonne|t|l|litre|hectolitre|hl)(s)? *(par hectare|\/ *hectare|\/ *ha)?) *(de|d\'|du)? *(la|le)? *#{matched}/
      end 

      def self.second_input_quantity(matched)
        /#{matched} *(à|a|avec)? *(\d{1,3}(\.|,)\d{1,2}|\d{1,3}) *((gramme|g|kg|kilo|kilogramme|tonne|t|hectolitre|hl|litre|l)(s)? *(par hectare|\/ *hectare|\/ *ha)?)/
      end 

    end 
  end 
end 