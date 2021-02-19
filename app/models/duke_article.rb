module Duke
  class DukeArticle
    include Duke::BaseDuke

    attr_accessor :description, :date, :duration, :offset, :user_input, :activity_variety, :tool, :cultivablezones, :financial_year, :entities
    @@user_specific_types = [:financial_year, :entities, :cultivablezones, :activity_variety, :plant, :land_parcel, :cultivation, :destination, :crop_groups, :tool, :doer, :input, :press] 
    @@ambiguities_types = [:plant, :land_parcel, :cultivation, :destination, :crop_groups, :tool, :doer, :input, :press]
    @@month_hash =  {"janvier" => 1, "jan" => 1, "février" => 2, "fev" => 2, "fevrier" => 2, "mars" => 3, "avril" => 4, "avr" => 4, "mai" => 5, "juin" => 6, "juillet" => 7, "juil" => 7, "août" => 8, "aou" => 8, "aout" => 8, "septembre" => 9, "sept" => 9, "octobre" => 10, "oct" => 10, "novembre" => 11, "nov" => 11, "décembre" => 12, "dec" => 12, "decembre" => 12 }
    
    def initialize(**args)
      @description, @user_input = "", ""
      @date = Time.now
      @duration = 60 
      args.each{|k, v| instance_variable_set("@#{k}", v)}
    end 

    # @creates intervention from json
    # @returns DukeIntervention
    def recover_from_hash(jsonD) 
      jsonD.slice(*@matchArrs).each{|k,v| self.instance_variable_set("@#{k}", DukeMatchingArray.new(arr: v))}
      jsonD.except(*@matchArrs).each{|k,v| self.instance_variable_set("@#{k}", v)}
      self
    end 

    # @returns DukeIntervention to_json with given parameters
    def to_jsonD(*args) 
      return ActiveSupport::HashWithIndifferentAccess.new(self.as_json) if args.empty?
      return ActiveSupport::HashWithIndifferentAccess.new(Hash[args.flatten.map{|arg| [arg, self.send(arg)] if self.respond_to? arg}.compact])
    end 

    # @param [json] jsonD : DukeArticle.as_json
    # @param [Float] level : min_match_level
    # Extract user specifics & recreates DukeArticle
    def extract_user_specifics(jsonD: self.to_jsonD, level: 66)
      @user_input = @user_input.duke_clear # Get clean string before parsing
      user_specifics = jsonD.select{ |key, value| @@user_specific_types.include?(key.to_sym)}
      attributes = user_specifics.to_h{|key, mArr|[key, {iterator: iterator(key.to_sym), name_attribute: name_attr(key.to_sym), list: mArr}]}
      create_words_combo.each do |combo| # Creating all combo_words from user_input
        parser = DukeParser.new(word_combo: combo, level: level, attributes: attributes) # create new DukeParser
        parser.parse # parse user_specifics
      end
      self.recover_from_hash(jsonD) # recreate DukeArticle
    end
          
    def update_description(ds)
      @description += " - #{ds}"
    end 

    def reset_retries
      @retry = 0
    end 

    # Find ambiguities in what's been parsed
    def find_ambiguity
      self.as_json.each do |key, reco|
        if @@ambiguities_types.include?(key.to_sym)
          ambiguity_attr = ambiguities_attributes(key.to_sym)
          reco.each do |anItem|
            ambiguity_check(itm: anItem, ambiguity_attr: ambiguity_attr, itm_type: key) unless anItem.distance == 1
          end
        end
      end
    end

    # @params [String] type : type of ambiguity to be corrected 
    # @params [Integer] key : key of ambiguous item
    def correct_ambiguity(type:, key:)
      current_hash = self.instance_variable_get("@#{type}").find_by_key(key)
      self.instance_variable_get("@#{type}").delete(current_hash)
      begin
        @user_input.split(/[|]{3}/).map{|chosen| eval(chosen)}.each do |chosen_one| 
          chosen_one[:rate] = {unit: :population, value: nil} if current_hash.needs_input_reinitialize?(chosen_one)
          self.update_description(chosen_one[:name])
          self.instance_variable_get("@#{chosen_one[:type]}").push(DukeMatchingItem.new(hash: current_hash.merge_h(chosen_one)))
        end 
      rescue SyntaxError, StandardError
        puts "User didn't click Buttons grrr"
      ensure
        self.instance_variable_set("@#{type}", self.instance_variable_get("@#{type}").uniq_by_key)
        @ambiguities.shift
      end 
    end 

    # TODO : check if really usefull
    def to_ibm(**opt)
      what_next, sentence, optional = redirect
      return { parsed: self.to_jsonD, sentence: sentence, redirect: what_next, optional: optional}.merge(opt)
    end 

    # Extracts date with correct hour from @user_input
    # @return nil, but set @date
    def extract_date
      now = Time.now
      time = extract_hour(@user_input) # Extract hour from user_input
      if @user_input.matchdel(/avant( |-)?hier/) # Look for specific keywords
        d = Date.yesterday.prev_day
      elsif @user_input.matchdel("hier")
        d = Date.yesterday
      elsif @user_input.matchdel("demain")
        d = Date.tomorrow
      else
        if full_date = @user_input.matchdel(/(\d|\d{2})(er|eme|ème)? *(janvier|jan|février|fev|fevrier|mars|avril|avr|mai|juin|juillet|jui|aout|aou|août|septembre|sept|octobre|oct|novembre|nov|décembre|dec|decembre) ?(\d{4})?/)
          @date = Time.new(year_from_str(full_date[4]), @@month_hash[full_date[3]], full_date[1].to_i, time.hour, time.min, time.sec); return 
        elsif slash_date = @user_input.matchdel(/(0[1-9]|[1-9]|1[0-9]|2[0-9]|3[0-1])[\/](0[1-9]|1[0-2]|[1-9])([\/](\d{4}|\d{2}))?/)
          @date = Time.new(year_from_str(slash_date[4]), slash_date[2].to_i, slash_date[1].to_i, time.hour, time.min, time.sec); return
        else # If nothing matched, we return todays date
          @date = Time.new(now.year, now.month, now.day, time.hour, time.min, time.sec); return
        end
      end
      @date = Time.new(d.year, d.month, d.day, time.hour, time.min, time.sec) # Set correct time to date if match
      @offset = "+0#{Time.at(@date.to_time).utc_offset / 3600}:00"
    end

    # @return [Datetime(start), Datetime(end)]
    def extract_time_interval
      now = Time.now
      since_date = @user_input.matchdel(/(depuis|à partir|a partir) *(du|de|le|la)? *(\d|\d{2}) *(janvier|jan|février|fev|fevrier|mars|avril|avr|mai|juin|juillet|jui|aout|aou|août|septembre|sept|octobre|oct|novembre|nov|décembre|dec|decembre)( *\d{4})?/)
      since_slash_date = @user_input.matchdel(/(depuis|à partir|a partir) * (du|de|le|la)? *(0[1-9]|[1-9]|1[0-9]|2[0-9]|3[0-1])[\/](0[1-9]|1[0-2]|[1-9])([\/](\d{4}|\d{2}))?/)
      since_month_date = @user_input.matchdel(/(depuis|à partir|a partir) *(du|de|le|la)? *(janvier|jan|février|fev|fevrier|mars|avril|avr|mai|juin|juillet|jui|aout|aou|août|septembre|sept|octobre|oct|novembre|nov|décembre|dec|decembre)/)
      if @user_input.matchdel("ce mois")
        return Time.new(now.year, now.month, 1, 0, 0, 0), now
      elsif @user_input.matchdel("cette semaine")
        return now - (now.wday - 1), now
      elsif since_date 
        return Time.new(year_from_str(since_date[5]), @@month_hash[since_date[4]], since_date[3].to_i, 0, 0, 0), now
      elsif since_slash_date
        return Time.new(year_from_str(since_slash_date[6]), since_slash_date[4].to_i, since_slash_date[3].to_i, 0, 0, 0), now
      elsif since_month_date 
        year = (now.year - 1 if month > now.month)||now.year
        return Time.new(year, @@month_hash[since_month_date[3]], 1, 0, 0, 0), now
      else 
        return Time.new(now.year, 1, 1, 0, 0, 0), now
      end 
    end 

    private 

    # Extracts duration from user_input
    # @return nil but set @duration in minutes
    def extract_duration
        if @user_input.matchdel("trois quarts d'heure") # Look for non-numeric values
          @duration = 45 ; return
        elsif @user_input.matchdel("quart d'heure")
          @duration = 15; return
        elsif @user_input.matchdel("demi heure")
          @duration = 30; return
        end
        delta_in_mins = 0
        if min_time = @user_input.matchdel(/\d+\s(\w*minute\w*|mins)/) # Extract MM regex
          delta_in_mins += min_time[0].to_i
        elsif hour_min_time = @user_input.matchdel(/(de|pendant|durée) *(\d{1,2})\s?(heures|h|heure)\s?(\d\d)/) # Extract HH:MM regex
          delta_in_mins += hour_min_time[2].to_i*60 + hour_min_time[4].to_i
        elsif hour_time = @user_input.matchdel(/(de|pendant|durée) *(\d{1,2})\s?(h\b|h\s|heure)/) # Extract HH: regex
          delta_in_mins += hour_time[2].to_i*60
          delta_in_mins += 30 if @user_input.matchdel("et demi") # Check for "et demi" in user_input
        else
          delta_in_mins = nil # Set duration to nil on default
        end 
        @duration = delta_in_mins
    end

    # @param [String] content
    # @return Datetime
    def extract_hour(content = @user_input)
      now = Time.now
      time = content.matchdel(/\b(00|[0-9]|1[0-9]|2[0-3]) *(h|heure(s)?|:) *([0-5]?[0-9])?\b/) # matching time regex
      return Time.new(now.year, now.month, now.day, time[1].to_i, (0 if time[4].nil?)||time[4].to_i, 0) if time # if we match, we return correct hour
      {8 => "matin", 14 => "après-midi", 12 => "midi", 20 => "soir", 0 => "minuit"}.each do |hour, val| # if any_word matches, we return correct hour
        return Time.new(now.year, now.month, now.day, hour, 0, 0) if content.matchdel(val) 
      end 
      return Time.now # If nothing matches, we return current hour
    end



    # @param [Str|Integer|Float] year
    # @return [Integer] parsed year
    def year_from_str year
      now = Time.now
      return 2000 + year.to_i if year.to_i.between?(now.year - 2005, now.year - 1999)
      return year.to_i if year.to_i.between?(now.year - 5, now.year + 1)
      return now.year
    end 

    # @param [Integer] value : Integer extracted by ibm
    # @return [Stringified float or integer] || [nilType]
    def extract_number_parameter(value)
      match_to_float = @user_input.match(/#{value}((\.|,)\d{1,2})/) unless value.nil? #check for float when watson returns integer
      hasNumbers = @user_input.match('\d{1,4}((\.|,)\d{1,2})?') #check for number inside user_input
      if value.nil?
        value = hasNumbers[0].gsub(',','.').gsub(' ','') if hasNumbers
        return nil unless hasNumbers
      elsif match_to_float
        value = match_to_float[0]
      end
      return value.to_s.gsub(',','.') # returning value as a string
    end

    # Choose between new_date & @date
    def choose_date new_date
      @date = new_date if (new_date.to_time - Time.now).abs > 300
    end

    # Choose between new_duration and @duration
    def choose_duration new_duration
      @duration = new_duration unless new_duration.kind_of?(Array) && new_duration.size.eql?(2)
    end

    # @returns { [0]: "Je", [0,1]: "Je suis", [0,1,2]: "Je suis ton", [1]: "suis", [1,2]: "suis ton", [2]: "ton"} for @user_input = "Je suis ton"
    def create_words_combo
      idx_cb = (0..@user_input.duke_words.size).to_a.combination(2)
      return Hash[idx_cb.map{|i1, i2| [(i1..i2-1).to_a, @user_input.duke_words[i1..i2-1].join(" ")] if 4>= i2 - i1}.compact]
    end

    # @return true if there's nothing to iterate over
    def empty_iterator item_type 
      return true if item_type == :input && Procedo::Procedure.find(@procedure).parameters_of_type(:input).empty? 
      return true if item_type == :crop_groups && (defined? CropGroup).nil?
      return false
    end 

    # @return target_type given procedure_family
    def tar_from_procedure
      if (Procedo::Procedure.find(@procedure).activity_families & [:vine_farming]).any?
        return Procedo::Procedure.find(@procedure).parameters.find {|param| param.type == :target}.name, :crop_groups
      else  
        return :cultivablezones, :activity_variety, :crop_groups
      end 
    end 

    # @param [str] item_type 
    # @return item iname_attr for this item
    def name_attr(item_type)
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

    # @param [str] item_type 
    # @return iterator for this item
    def iterator(item_type) 
      if empty_iterator(item_type)
        iterator= []
      elsif item_type == :input
        iterator= Matter.availables(at: @date.to_time).of_expression(Procedo::Procedure.find(@procedure).parameters_of_type(:input).collect(&:filter).join(" or "))
      elsif item_type == :crop_groups
        iterator= CropGroup.all
      elsif item_type == :financial_year 
        iterator= FinancialYear.all
      elsif item_type == :activity_variety
        iterator = Activity.select('distinct on (cultivation_variety) *')
      elsif item_type == :press
        iterator = Matter.availables(at: @date.to_time).can('press(grape)', 'press(juice)', 'press(fermented_juice)', 'press(wine)')
      elsif item_type == :doer
        iterator = Worker.availables(at: @date.to_time).each
      elsif item_type == :entities 
        iterator = Entity.all
      elsif item_type == :destination
        iterator = Matter.availables(at: @date.to_time).where("variety='tank'")
      elsif item_type == :cultivablezones 
        iterator = CultivableZone.all
      elsif item_type == :tool
        iterator = Equipment.availables(at: @date.to_time)
      elsif item_type == :plant
        iterator = Plant.availables(at: @date.to_time)
      elsif item_type == :land_parcel
        iterator = LandParcel.availables(at: @date.to_time)
      elsif item_type == :cultivation
        iterator = Product.availables(at: @date.to_time).of_expression("is land_parcel or is plant")
      end
      return iterator
    end 

    # @param [str] item_type 
    # @return Array of Arrays with each type, and it's iterator & name_attr
    def ambiguities_attributes(item_type)
      type =  if ([:crop_groups, :plant, :land_parcel, :cultivation].include?(item_type) && @procedure.present?)
                tar_from_procedure
              elsif [:crop_groups, :plant, :land_parcel, :cultivation].include?(item_type)
                [:plant, :crop_groups]
              else  
                [item_type]
              end 
      return type.map{|ty| [ty, iterator(ty), name_attr(ty)]}
    end 

    # @param [DukeMatchingItem] itm 
    # @param [Array] ambiguity_attr : [[type, iterator, name_attr].foreach ambig_types]
    # @param [String] itm_type : Current itm type
    # Checks ambiguity for one item
    def ambiguity_check(itm:, ambiguity_attr:, itm_type:)
      ambiguity = DukeAmbiguity.new(itm: itm, ambiguity_attr: ambiguity_attr, itm_type: itm_type).check_ambiguity
      @ambiguities.push(ambiguity) unless ambiguity.empty?
    end 

  end
end
