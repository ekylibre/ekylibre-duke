module Duke
  module Utils
    class Regex

      # Dates & durations

      def self.minutes
        /\d+\s(\w*minute\w*|mins)/
      end

      def self.hours_minutes
        /(de|pendant|durée) *(\d{1,2})\s?(heures|h|heure)\s?(\d\d)/
      end

      def self.hours
        /(de|pendant|durée) *(\d{1,2})\s?(h\b|h\s|heure)/
      end

      def self.time
        /\b(00|[0-9]|1[0-9]|2[0-3]) *(h|heure(s)?|:) *([0-5]?[0-9])?\b/
      end

      def self.before_yesterday
        /avant( |-)?hier/
      end

      def self.full_date
        /(\d|\d{2})(er|eme|ème)? *(janvier|jan|février|fev|fevrier|mars|avril|avr|mai|juin|juillet|jui|aout|aou|août|septembre|sept|octobre|oct|novembre|nov|décembre|dec|decembre) ?(\d{4})?/
      end

      def self.slash_date
        /(0[1-9]|[1-9]|1[0-9]|2[0-9]|3[0-1])[\/](0[1-9]|1[0-2]|[1-9])([\/](\d{4}|\d{2}))?/
      end

      def self.afternoon_hour
        /\b(00|[0-9]|1[0-1]) *(h|heure(s)?|:) *([0-5]?[0-9])?\b *(du|de|cet|cette)? *(le|l')? *(aprem|apm|après-midi|apres midi|après midi|aprèm)/
      end

      def self.afternoon
        /(apr(e|è)?s( |-)?midi|apr(e|è)m|apm)/
      end

      def self.morning_hour
        /\b(00|[0-9]|1[0-1]) *(h|heure(s)?|:) *([0-5]?[0-9])?\b *(du|de|ce)? *matin/
      end

      def self.hour_interval
        /((de|à|a|entre) *\b((00|[0-9]|1[0-9]|2[0-3]) *(h|heure(s)?|:) *([0-5]?[0-9])?\b|midi|minuit) *(jusqu\')?(a|à|et) *\b((00|[0-9]|1[0-9]|2[0-3]) *(h|heure(s)?|:) *([0-5]?[0-9])?\b|midi|minuit))/
      end

      def self.since_date
        /(depuis|à partir|a partir) *(du|de|le|la)? *(\d|\d{2}) *(janvier|jan|février|fev|fevrier|mars|avril|avr|mai|juin|juillet|jui|aout|aou|août|septembre|sept|octobre|oct|novembre|nov|décembre|dec|decembre)( *\d{4})?/
      end

      def self.since_slash_date
        /(depuis|à partir|a partir) * (du|de|le|la)? *(0[1-9]|[1-9]|1[0-9]|2[0-9]|3[0-1])[\/](0[1-9]|1[0-2]|[1-9])([\/](\d{4}|\d{2}))?/
      end

      def self.since_month_date
        /(depuis|à partir|a partir) *(du|de|le|la)? *(janvier|jan|février|fev|fevrier|mars|avril|avr|mai|juin|juillet|jui|aout|aou|août|septembre|sept|octobre|oct|novembre|nov|décembre|dec|decembre)/
      end

      # Harvest Reception parameters

      def self.percentage
        /(\d{1,2}) *(%|pour( )?cent(s)?)/
      end

      def self.quantity
        /(\d{1,5}(\.|,)\d{1,2}|\d{1,5}) *(kilo|kg|hecto|expo|texto|hl|t\b|tonne)/
      end

      def self.conflicting_tav
        /(degré d\'alcool|alcool|degré|tavp|t avp2|tav|avp|t svp|pourcentage|t avait) *(jus de presse)? *(est|était)? *(égal +(a *|à *)?|= *|de *|à *)?(\d{1,2}(\.|,)\d{1,2}|\d{1,2}) *(degré)?/
      end

      def self.conflicting_temp
        /(température|temp) *(est|était)? *(égal *|= *|de *|à *)?(\d{1,2}(\.|,)\d{1,2}|\d{1,2}) *(degré)?/
      end

      def self.tav
        /(\d{1,2}|\d{1,2}(\.|,)\d{1,2}) ?((degré(s)?|°|%)|(de|en|d\')? *(tavp|t avp|tav|(t)? *avp|(t)? *svp|t avait|thé avait|thé à l\'épée|alcool|(entea|mta) *vp))/
      end

      def self.temp
        /(\d{1,2}|\d{1,2}(\.|,)\d{1,2}) +(degré|°)/
      end

      def self.ph
        /(\d{1,2}|\d{1,2}(\.|,)\d{1,2}) +(de +)?(ph|péage)/
      end

      def self.second_ph
        /((ph|péage) *(est|était)? *(égal *(a|à)? *|= ?|de +|à +)?)(\d{1,2}(\.|,)\d{1,2}|\d{1,2})/
      end

      def self.nitrogen
        /(azote aminé *(est|était)? *(égal +|= ?|de +)?(à)? *)(\d{1,3}(\.|,)\d{1,2}|\d{1,3})/
      end

      def self.second_nitrogen
        /(\d{1,3}|\d{1,3}(\.|,)\d{1,2}) +(mg|milligramme)?.?(par l|\/l|par litre)? ?+(d\'|de|en)? *azote aminé/
      end

      def self.ammo_nitrogen
        /(azote (ammoniacal|ammoniaque) *(est|était)? *(égal +|= ?|de +)?(à)? *)(\d{1,3}(\.|,)\d{1,2}|\d{1,3})/
      end

      def self.second_ammo_nitrogen
        /(\d{1,3}|\d{1,3}(\.|,)\d{1,2}) +(mg|milligramme)?.?(par l|\/l|par litre)? ?+(d\'|de|en)? *azote ammonia/
      end

      def self.assi_nitrogen
        /(\d{1,3}|\d{1,3}(\.|,)\d{1,2}) +(mg|milligramme)?.?(par l|\/l|par litre)? ?+(d\'|de|en)? ?+(azote *(assimilable)?|sel d\'ammonium|substance(s)? azotée)/
      end

      def self.second_assi_nitrogen
        /((azote *(assimilable)?|sel d\'ammonium|substance azotée) *(est|était)? *(égal +|= ?|de +)?(à)? *)(\d{1,3}(\.|,)\d{1,2}|\d{1,3})/
      end

      def self.sanitary_state
        '(état sanitaire) *(.*?)(destination|tav|\d{1,3} *(kg|hecto|kilo|hl|tonne)|cuve|degré|température|pourcentage|alcool|ph|péage|azote|acidité|malique|manuel|mécanique|hectare|$)'
      end

      def self.h2so4
        /(\d{1,3}|\d{1,3}(\.|,)\d{1,2}) +(g|gramme)?.? *(par l|\/l|par litre)? ?+(d\'|de|en)? ?+(acidité|acide|h2so4)/
      end

      def self.second_h2so4
        /(acide|acidité|h2so4) *(est|était)? *(égal.? *(a|à)?|=|de|à|a)? *(\d{1,3}(\.|,)\d{1,2}|\d{1,3})/
      end

      def self.malic
        /(\d{1,3}|\d{1,3}(\.|,)\d{1,2}) *(g|gramme)?.?(par l|\/l|par litre)? *(d\'|de|en)? *(acide?) *(malique|malic)/
      end

      def self.second_malic
        /((acide *)?(malic|malique) *(est|était)? *(égal +|= ?|de +|à +)?)(\d{1,3}(\.|,)\d{1,2}|\d{1,3})/
      end

      def self.first_area(matched)
        /(\d{1,2}) *(%|pour( )?cent(s)?) *(de *(la|l\')?|du|des|sur|à|a|au)? #{matched}/
      end

      def self.second_area(matched)
        /(\d{1,3}|\d{1,3}(\.|,)\d{1,2}) *((hect)?are(s)?) *(de *(la|l\')?|du|des|sur|à|a|au)? #{matched}/
      end

      # Utils

      def self.up_to_four_digits_float
        /\d{1,4}((\.|,)\d{1,2})?/
      end

      def self.int_to_float(value)
        /#{value}((\.|,)\d{1,2})/
      end

      # Inputs quantity

      def self.input_quantity(matched)
        /(\d{1,3}(\.|,)\d{1,2}|\d{1,3}) *((g|gramme|kg|kilo|kilogramme|tonne|t|l|litre|hectolitre|hl)(s)? *(par hectare|\/ *hectare|\/ *ha)?) *(de|d\'|du)? *(la|le)? *#{matched}/
      end

      def self.second_input_quantity(matched)
        /#{matched} *(à|a|avec)? *(\d{1,3}(\.|,)\d{1,2}|\d{1,3}) *((gramme|g|kg|kilo|kilogramme|tonne|t|hectolitre|hl|litre|l)(s)? *(par hectare|\/ *hectare|\/ *ha)?)/
      end

      # Intervention readings

      def self.bud_charge
        /(\d{1,2}) *(bourgeons|yeux|oeil)/
      end

      def self.second_bud_charge
        /charge *(de|à|avec|a)? *(\d{1,2})/
      end

      # Sentence cleaning 
      
      def self.numeroes
        /(\bnum(e|é)ro\b|n ?°)/
      end 

      def self.useless_words
        /\b(le|la|les)\b/
      end 

      def self.useless_characters
        /(#|-|_|\\)/
      end

      def self.multiple_whitespaces
        /(?<=\s)\s/
      end

    end
  end
end
