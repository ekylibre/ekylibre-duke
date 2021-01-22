module Duke
  module Models
    class DukeArticle
      include Duke::BaseDuke
      attr_accessor :description, :date, :duration, :user_input
      @@user_specific_types = [:financial_year, :entities, :cultivablezones, :activity_variety, :plant, :land_parcel, :cultivation, :destination, :crop_groups, :equipments, :workers, :inputs, :press] 
      @@month_hash =  {"janvier" => 1, "jan" => 1, "février" => 2, "fev" => 2, "fevrier" => 2, "mars" => 3, "avril" => 4, "avr" => 4, "mai" => 5, "juin" => 6, "juillet" => 7, "juil" => 7, "août" => 8, "aou" => 8, "aout" => 8, "septembre" => 9, "sept" => 9, "octobre" => 10, "oct" => 10, "novembre" => 11, "nov" => 11, "décembre" => 12, "dec" => 12, "decembre" => 12 }
      
      def initialize 
        @description, @user_input = "", ""
        @date = Time.now
        @duration = 60 
      end 

      def extract_duration
          #Function that finds the duration of the intervention & converts this value in minutes using regexes to have it stored into Ekylibre
          delta_in_mins = 0
          regex = '\d+\s(\w*minute\w*|mins)'
          regex2 = '(de|pendant|durée) *(\d{1,2})\s?(heures|h|heure)\s?(\d\d)'
          regex3 = '(de|pendant|durée) *(\d{1,2})\s?(h\b|h\s|heure)'
          # If @user_input includes a non numeric value, we catch it & return this duration
          if @user_input.include? "trois quarts d'heure"
            @user_input["trois quart d'heure"] = ""
            @duration = 45
            return
          elsif @user_input.include? "quart d'heure"
            @user_input["quart d'heure"] = ""
            @duration = 15
            return
          elsif @user_input.include? "demi heure"
            @user_input["demi heure"] = ""
            @duration = 30
            return
          end
          min_time = @user_input.match(regex)
          hour_min_time = @user_input.match(regex2)
          hour_time = @user_input.match(regex3)
          # If any regex matches, we extract the min value
          if min_time
            delta_in_mins += min_time[0].to_i
            @user_input[min_time[0]] = ""
          elsif hour_min_time
            delta_in_mins += hour_min_time[2].to_i*60
            delta_in_mins += hour_min_time[4].to_i
            @user_input[hour_min_time[0]] = ""
          elsif hour_time
            delta_in_mins += hour_time[2].to_i*60
            @user_input[hour_time[0]] = ""
            # If "et demi" in sentence, we add 30min to what's already parsed
            if @user_input.include? "et demi"
              delta_in_mins += 30
              @user_input["et demi"] = ""
            end
          else
            # If nothing matched, we return the basic duration => 1 hour
            delta_in_mins = 60
          end 
          @duration = delta_in_mins
      end

      def extract_date
        # Extract date from a string, and returns a dateTime object with appropriate date & time
        # Default value is Datetime.now
        now = DateTime.now
        full_date_regex = '(\d|\d{2})(er|eme|ème)? *(janvier|jan|février|fev|fevrier|mars|avril|avr|mai|juin|juillet|jui|aout|aou|août|septembre|sept|octobre|oct|novembre|nov|décembre|dec|decembre)( *\d{4})?'
        slash_date_regex = '(0[1-9]|[1-9]|1[0-9]|2[0-9]|3[0-1])[\/](0[1-9]|1[0-2]|[1-9])([\/](\d{4}|\d{2}))?'
        # Extract the hour at which intervention was done
        time = extract_hour(@user_input)
        # Search for keywords and define a d=DateTime if match
        if @user_input.include? "avant-hier"
          @user_input["avant-hier"] = ""
          d = Date.yesterday.prev_day
        elsif @user_input.include? "hier"
          @user_input["hier"] = ""
          d = Date.yesterday
        elsif @user_input.include? "demain"
          @user_input["demain"] = ""
          d = Date.tomorrow
        else
          # If no keyword, try to match regexes and return 
          full_date = @user_input.match(full_date_regex)
          slash_date = @user_input.match(slash_date_regex)
          if full_date
            @user_input[full_date[0]] = ""
            day = full_date[1].to_i
            month = @@month_hash[full_date[3]]
            if full_date[3].to_i.between?(now.year - 5, now.year + 1)
              year = full_date[3].to_i
            else
              year = now.year
            end
            @date = DateTime.new(year, month, day, time.hour, time.min, time.sec, "+0#{Time.now.utc_offset / 3600}:00")
            return 
          elsif slash_date
            @user_input[slash_date[0]] = ""
            day = slash_date[1].to_i
            month = slash_date[2].to_i
            if slash_date[4].to_i.between?(now.year - 2005, now.year - 1999)
              year = 2000 + slash_date[4].to_i
            elsif slash_date[4].to_i.between?(now.year - 5, now.year + 1)
              year = slash_date[4].to_i
            else
              year = now.year
            end
            @date = DateTime.new(year, month, day, time.hour, time.min, time.sec, "+0#{Time.now.utc_offset / 3600}:00")
            return
          else
            # If nothing matches, we return DateTime.now item, with extracted time
            @date = DateTime.new(now.year, now.month, now.day, time.hour, time.min, time.sec, "+0#{Time.now.utc_offset / 3600}:00")
            return
          end
        end
        # If a d object is set, return the DateTime object with extracted time
        @date = DateTime.new(d.year, d.month, d.day, time.hour, time.min, time.sec, "+0#{Time.now.utc_offset / 3600}:00")
      end

      def extract_time_interval
        # Extracting long duration time
        now = DateTime.now
        since_regex = '(depuis|à partir|a partir) *(du|de|le|la)? *(\d|\d{2}) *(janvier|jan|février|fev|fevrier|mars|avril|avr|mai|juin|juillet|jui|aout|aou|août|septembre|sept|octobre|oct|novembre|nov|décembre|dec|decembre)( *\d{4})?'
        since_slash_regex = '(depuis|à partir|a partir) * (du|de|le|la)? *(0[1-9]|[1-9]|1[0-9]|2[0-9]|3[0-1])[\/](0[1-9]|1[0-2]|[1-9])([\/](\d{4}|\d{2}))?'
        since_month_regex = '(depuis|à partir|a partir) *(du|de|le|la)? *(janvier|jan|février|fev|fevrier|mars|avril|avr|mai|juin|juillet|jui|aout|aou|août|septembre|sept|octobre|oct|novembre|nov|décembre|dec|decembre)'
        since_date = @user_input.match(since_regex)
        since_slash_date = @user_input.match(since_slash_regex)
        since_month_date = @user_input.match(since_month_regex)
        if @user_input.include? "cette année"
          @user_input["cette année"] = ""
          return DateTime.new(now.year, 1, 1, 0, 0, 0), now
        elsif @user_input.include? "ce mois"
          @user_input["ce mois"] = ""
          return DateTime.new(now.year, now.month, 1, 0, 0, 0), now
        elsif @user_input.include? "cette semaine"
          @user_input["cette semaine"] = ""
          return now - (now.wday - 1), now
        elsif since_date 
          @user_input[since_date[0]] = ""
          day = since_date[3].to_i
          month = @@month_hash[since_date[4]]
          if since_date[5].to_i.between?(now.year - 5, now.year + 1)
            year = since_date[5].to_i
          else
            year = now.year
          end
          return DateTime.new(year, month, day, 0, 0, 0), now
        elsif since_slash_date
          @user_input[since_slash_date[0]] = ""
          day = since_slash_date[3].to_i
          month = since_slash_date[4].to_i
          if since_slash_date[6].to_i.between?(now.year - 2005, now.year - 1999)
            year = 2000 + since_slash_date[4].to_i
          elsif since_slash_date[6].to_i.between?(now.year - 5, now.year + 1)
            year = since_slash_date[4].to_i
          else
            year = now.year
          end
          return DateTime.new(year, month, day, 0, 0, 0), now
        elsif since_month_date
          @user_input[since_month_date[0]] = ""
          month = @@month_hash[since_month_date[3]]
          if month > now.month 
            year = now.year - 1 
          else 
            year = now.year 
          end 
          return DateTime.new(year, month, 1, 0, 0, 0), now
        else 
          return now - 1.year, now
        end 
      end 

      def extract_hour(content = @user_input)
        # Extract hour from a string, returns a DateTime object with appropriate date
        # Default value is Time.now
        now = DateTime.now
        time_regex = '\b(00|[0-9]|1[0-9]|2[0-3]) *(h|heure(s)?|:) *([0-5]?[0-9])?\b'
        # Try to match the time regex & Return DateTime with todays date and correct time
        time = content.match(time_regex)
        if time
          if time[4].nil?
            content[time[0]] = ""
            return DateTime.new(now.year, now.month, now.day, time[1].to_i, 0, 0)
          else
            content[time[0]] = ""
            return DateTime.new(now.year, now.month, now.day, time[1].to_i, time[4].to_i, 0)
          end
        # Otherwise try to match keywords
        elsif content.include? "matin"
          content["matin"] = ""
          return DateTime.new(now.year, now.month, now.day, 10, 0, 0)
        elsif content.include? "après-midi"
          content["après-midi"] = ""
          return DateTime.new(now.year, now.month, now.day, 17, 0, 0)
        elsif content.include? "midi"
          content["midi"] = ""
          return DateTime.new(now.year, now.month, now.day, 12, 0, 0)
        elsif content.include? "soir"
          content["soir"] = ""
          return DateTime.new(now.year, now.month, now.day, 20, 0, 0)
        elsif content.include? "minuit"
          content["minuit"] = ""
          return DateTime.new(now.year, now.month, now.day, 0, 0, 0)
        else
          return DateTime.now
        end
      end

      # TODO : Refacto this fn 
      def extract_number_parameter(value)
        # Extract a value from a sentence. A value can already be specified, in this case, we look for a float with values int
        match_to_float = @user_input.match(/#{value}((\.|,)\d{1,2})/) unless value.nil?
        if value.nil?
          # If we don't have a value, we search for an integer/float inside the user input
          hasNumbers = @user_input.match('\d{1,4}((\.|,)\d{1,2})?')
          if hasNumbers
            value = hasNumbers[0].gsub(',','.').gsub(' ','')
          else
            return value
          end
        # If we have a value, we should check if watson didn't return an integer instead of a float
        elsif match_to_float
          value = match_to_float[0]
        end
        # Return the value as a string
        return value.to_s.gsub(',','.')
      end

      def choose_date new_date
        #Date.now is the default value, so if the value returned is more than 15 min away from now, we select it
        @date = new_date if (new_date.to_datetime - DateTime.now).abs > 0.010
      end

      def choose_duration new_duration
        #Default duration is 60, so select the first one if differents, otherwise the second
        @duration = new_duration unless new_duration.eql? 60
      end

      def all_words
        return @user_input.split /\s+|\'/
      end 

      def create_words_combo
        # Creating words combos with_index
        # "Je suis ton " becomes { [0] => "Je", [0,1] => "Je suis", [0,1,2] => "Je suis ton", [1] => "suis", [1,2] => "suis ton", [2] => "ton"}
        idx_cb = (0..all_words.size).to_a.combination(2)
        return Hash[idx_cb.map{|i1, i2| [(i1..i2-1).to_a, all_words[i1..i2-1].join(" ")] if 4>= i2 - i1}.compact]
      end

      #TODO : Rename :input, :tool and jsut do returnTrue if Procedo::Procedure.find...item_type.empty?
      def empty_iterator item_type 
        return true if item_type == :inputs && Procedo::Procedure.find(@procedure).parameters_of_type(:input).empty? 
        return true if item_type == :crop_groups && (defined? CropGroup).nil?
        return false
      end 

      def tar_from_procedure
        if (Procedo::Procedure.find(@procedure).activity_families & [:vine_farming]).any?
          return Procedo::Procedure.find(@procedure).parameters.find {|param| param.type == :target}.name, :crop_groups
        else  
          return :cultivablezones, :activity_variety, :crop_groups
        end 
      end 

      def name_attr(item_type)
        # Returns correct attributes that display interesting name to iterate over, given what item_type we're looking for
        if item_type == :activity_variety
          attribute = :cultivation_variety_name
        elsif item_type == :entities
          attribute = :full_name
        elsif item_type == :financial_year
          attribute = :code 
        else 
          attribute = :name
        end
        attribute
      end 

      def iterator(item_type) 
        # Returns correct array to iterate over, given what item_type we're looking 
        if empty_iterator(item_type)
          iterator= []
        elsif item_type == :inputs
          iterator= Matter.availables(at: @date.to_datetime).of_expression(Procedo::Procedure.find(@procedure).parameters_of_type(:input).collect(&:filter).join(" or "))
        elsif item_type == :crop_groups
          iterator= CropGroup.all
        elsif item_type == :financial_year 
          iterator= FinancialYear.all
        elsif item_type == :activity_variety
          iterator = Activity.select('distinct on (cultivation_variety) *')
        elsif item_type == :press
          iterator = Matter.availables(at: @date.to_datetime).can('press(grape)')
        elsif item_type == :workers
          iterator = Worker.availables(at: @date.to_datetime).each
        elsif item_type == :entities 
          iterator = Entity.all
        elsif item_type == :destination
          iterator = Matter.availables(at: @date.to_datetime).where("variety='tank'")
        elsif item_type == :cultivablezones 
          iterator = CultivableZone.all
        elsif item_type == :equipments
          iterator = Equipment.availables(at: @date.to_datetime)
        elsif item_type == :plant
          iterator = Plant.availables(at: @date.to_datetime)
        elsif item_type == :land_parcel
          iterator = LandParcel.availables(at: @date.to_datetime)
        elsif item_type == :cultivation
          iterator = Product.availables(at: @date.to_datetime).of_expression("is land_parcel or is plant")
        end
        return iterator
      end 

      def ambiguities_attributes(item_type)
        type =  if [:crop_groups, :plant, :land_parcel, :cultivation].include?(item_type)
                  tar_from_procedure
                else 
                  [item_type]
                end 
        return type.map{|ty| [ty, iterator(ty), name_attr(ty)]}
      end 
      
      # TODO : Create groups of what to look for : targets -> [:plant, :crop_group, :...], make giga iterator, with bigger matching level
      def find_ambiguity
        # Find ambiguities in what's been parsed, ie items with close fuzzy match the best words that matched
        self.as_json.each do |key, reco|
          if @@user_specific_types.include?(key.to_sym)
            ambiguity_attr = ambiguities_attributes(key.to_sym)
            reco.each do |anItem|
              ambiguity_check(itm: anItem, ambiguity_attr: ambiguity_attr, itm_type: key) unless anItem.distance == 1
            end
          end
        end
      end

      def ambiguity_check(itm:, ambiguity_attr:, itm_type:)
        # Method to check ambiguity about a specific item
        ambiguity = Duke::Models::DukeAmbiguity.new(itm: itm, ambiguity_attr: ambiguity_attr, itm_type: itm_type).check_ambiguity
        @ambiguities.push(ambiguity) unless ambiguity.empty?
      end 

      def extract_user_specifics(jsonD: self.to_jsonD, level: 0.89)
        # Function used for extracting specific elements of every type that's in parsed & @user_specifics, with minimum matching % level from user_input
        # Find all types that we're gonna check, and their values
        user_specifics = jsonD.select{ |key, value| @@user_specific_types.include?(key.to_sym)}
        attributes = user_specifics.to_h{|key, mArr|[key, {iterator: iterator(key.to_sym), name_attribute: name_attr(key.to_sym), list: mArr}]}
        create_words_combo.each do |combo| # Creating all combo_words from user_input
          parser = Duke::Models::DukeParser.new(word_combo: combo, attributes: attributes)
          parser.parse
        end
        self.recover_from_hash(jsonD)
      end

    end
  end
end
