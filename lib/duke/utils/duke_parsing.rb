module Duke
  module Utils
    class DukeParsing
      @@fuzzloader = FuzzyStringMatch::JaroWinkler.create( :pure )
      @@user_specific_types = [:financial_year, :entities, :cultivablezones, :activity_variety, :plant, :land_parcel, :cultivation, :destination, :crop_groups, :equipments, :workers, :inputs, :press] 
      @@month_hash = {"janvier" => 1, "jan" => 1, "février" => 2, "fev" => 2, "fevrier" => 2, "mars" => 3, "avril" => 4, "avr" => 4, "mai" => 5, "juin" => 6, "juillet" => 7, "juil" => 7, "août" => 8, "aou" => 8, "aout" => 8, "septembre" => 9, "sept" => 9, "octobre" => 10, "oct" => 10, "novembre" => 11, "nov" => 11, "décembre" => 12, "dec" => 12, "decembre" => 12 }

      def extract_duration(content)
          #Function that finds the duration of the intervention & converts this value in minutes using regexes to have it stored into Ekylibre
          delta_in_mins = 0
          regex = '\d+\s(\w*minute\w*|mins)'
          regex2 = '(de|pendant|durée) *(\d{1,2})\s?(heures|h|heure)\s?(\d\d)'
          regex3 = '(de|pendant|durée) *(\d{1,2})\s?(h\b|h\s|heure)'
          # If content includes a non numeric value, we catch it & return this duration
          if content.include? "trois quarts d'heure"
            content["trois quart d'heure"] = ""
            return 45
          end
          if content.include? "quart d'heure"
            content["quart d'heure"] = ""
            return 15
          end
          if content.include? "demi heure"
            content["demi heure"] = ""
            return 30
          end
          min_time = content.match(regex)
          hour_min_time = content.match(regex2)
          hour_time = content.match(regex3)
          # If any regex matches, we extract the min value
          if min_time
            delta_in_mins += min_time[0].to_i
            content[min_time[0]] = ""
          elsif hour_min_time
            delta_in_mins += hour_min_time[2].to_i*60
            delta_in_mins += hour_min_time[4].to_i
            content[hour_min_time[0]] = ""
          elsif hour_time
            delta_in_mins += hour_time[2].to_i*60
            content[hour_time[0]] = ""
            # If "et demi" in sentence, we add 30min to what's already parsed
            if content.include? "et demi"
              delta_in_mins += 30
              content["et demi"] = ""
            end
          else
            # If nothing matched, we return the basic duration => 1 hour
            delta_in_mins = 60
          end 
          return delta_in_mins
      end

      def extract_date(content)
        # Extract date from a string, and returns a dateTime object with appropriate date & time
        # Default value is Datetime.now
        now = DateTime.now
        full_date_regex = '(\d|\d{2})(er|eme|ème)? *(janvier|jan|février|fev|fevrier|mars|avril|avr|mai|juin|juillet|jui|aout|aou|août|septembre|sept|octobre|oct|novembre|nov|décembre|dec|decembre)( *\d{4})?'
        slash_date_regex = '(0[1-9]|[1-9]|1[0-9]|2[0-9]|3[0-1])[\/](0[1-9]|1[0-2]|[1-9])([\/](\d{4}|\d{2}))?'
        # Extract the hour at which intervention was done
        time = extract_hour(content)
        # Search for keywords and define a d=DateTime if match
        if content.include? "avant-hier"
          content["avant-hier"] = ""
          d = Date.yesterday.prev_day
        elsif content.include? "hier"
          content["hier"] = ""
          d = Date.yesterday
        elsif content.include? "demain"
          content["demain"] = ""
          d = Date.tomorrow
        else
          # If no keyword, try to match regexes and return 
          full_date = content.match(full_date_regex)
          slash_date = content.match(slash_date_regex)
          if full_date
            content[full_date[0]] = ""
            day = full_date[1].to_i
            month = @@month_hash[full_date[3]]
            if full_date[3].to_i.between?(now.year - 5, now.year + 1)
              year = full_date[3].to_i
            else
              year = now.year
            end
            return DateTime.new(year, month, day, time.hour, time.min, time.sec, "+0#{Time.now.utc_offset / 3600}:00")
          elsif slash_date
            content[slash_date[0]] = ""
            day = slash_date[1].to_i
            month = slash_date[2].to_i
            if slash_date[4].to_i.between?(now.year - 2005, now.year - 1999)
              year = 2000 + slash_date[4].to_i
            elsif slash_date[4].to_i.between?(now.year - 5, now.year + 1)
              year = slash_date[4].to_i
            else
              year = now.year
            end
            return DateTime.new(year, month, day, time.hour, time.min, time.sec, "+0#{Time.now.utc_offset / 3600}:00")
          else
            # If nothing matches, we return DateTime.now item, with extracted time
            return DateTime.new(now.year, now.month, now.day, time.hour, time.min, time.sec, "+0#{Time.now.utc_offset / 3600}:00")
          end
        end
        # If a d object is set, return the DateTime object with extracted time
        return DateTime.new(d.year, d.month, d.day, time.hour, time.min, time.sec, "+0#{Time.now.utc_offset / 3600}:00")
      end

      def extract_time_interval(content)
        # Extracting long duration time
        now = DateTime.now
        since_regex = '(depuis|à partir|a partir) *(du|de|le|la)? *(\d|\d{2}) *(janvier|jan|février|fev|fevrier|mars|avril|avr|mai|juin|juillet|jui|aout|aou|août|septembre|sept|octobre|oct|novembre|nov|décembre|dec|decembre)( *\d{4})?'
        since_slash_regex = '(depuis|à partir|a partir) * (du|de|le|la)? *(0[1-9]|[1-9]|1[0-9]|2[0-9]|3[0-1])[\/](0[1-9]|1[0-2]|[1-9])([\/](\d{4}|\d{2}))?'
        since_month_regex = '(depuis|à partir|a partir) *(du|de|le|la)? *(janvier|jan|février|fev|fevrier|mars|avril|avr|mai|juin|juillet|jui|aout|aou|août|septembre|sept|octobre|oct|novembre|nov|décembre|dec|decembre)'
        since_date = content.match(since_regex)
        since_slash_date = content.match(since_slash_regex)
        since_month_date = content.match(since_month_regex)
        if content.include? "cette année"
          content["cette année"] = ""
          return DateTime.new(now.year, 1, 1, 0, 0, 0), now
        elsif content.include? "ce mois"
          content["ce mois"] = ""
          return DateTime.new(now.year, now.month, 1, 0, 0, 0), now
        elsif content.include? "cette semaine"
          content["cette semaine"] = ""
          return now - (now.wday - 1), now
        elsif since_date 
          content[since_date[0]] = ""
          day = since_date[3].to_i
          month = @@month_hash[since_date[4]]
          if since_date[5].to_i.between?(now.year - 5, now.year + 1)
            year = since_date[5].to_i
          else
            year = now.year
          end
          return DateTime.new(year, month, day, 0, 0, 0), now
        elsif since_slash_date
          content[since_slash_date[0]] = ""
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
          content[since_month_date[0]] = ""
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

      def extract_hour(content)
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

      def extract_number_parameter(value, content)
        # Extract a value from a sentence. A value can already be specified, in this case, we look for a float with values int
        match_to_float = content.match(/#{value}((\.|,)\d{1,2})/) unless value.nil?
        if value.nil?
          # If we don't have a value, we search for an integer/float inside the user input
          hasNumbers = content.match('\d{1,4}((\.|,)\d{1,2})?')
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

      def choose_date(date1, date2)
        #Date.now is the default value, so if the value returned is more than 15 min away from now, we select it
        if (date1.to_datetime - DateTime.now).abs >= 0.010
          return date1
        else
          return date2
        end
      end

      def choose_duration(duration1, duration2)
        #Default duration is 60, so select the first one if differents, otherwise the second
        if duration1 != 60
          return duration1
        else
          return duration2
        end
      end

      def add_to_recognized(saved_hash, list, all_lists, content)
        #Function that adds elements to a list of recognized items only if no other elements uses the same words to match or if this word has a lower fuzzmatch
        #If no element inside any of the lists has the same words used to match an element (overlapping indexes), and no duplicate => we push the hash to the list
        if not all_lists.any? {|aList| aList.any? {|recon_element| !(recon_element[:indexes] & saved_hash[:indexes]).empty?}}
          unless key_duplicate?(list, saved_hash)
            list.push(saved_hash)
          end
        # Else if one or multiple elements uses the same words -> if the distance is greater for this hash -> Remove other ones and add this one
        elsif not all_lists.any? {|aList| aList.any? {|recon_element| !(recon_element[:indexes] & saved_hash[:indexes]).empty? and !better_corrected_distance?(saved_hash, recon_element, content)}}
          # Check for duplicates in the list, if clear : -> remove value from any list with indexes overlapping and add current match to our list
          unless key_duplicate?(list, saved_hash)
            list_where_removing = all_lists.find{ |aList| aList.any? {|recon_element| !(recon_element[:indexes] & saved_hash[:indexes]).empty?}}
            unless list_where_removing.nil?
              item_to_remove = list_where_removing.find {|hash|!(hash[:indexes] & saved_hash[:indexes]).empty?}
              list_where_removing.delete(item_to_remove)
            end
            list.push(saved_hash)
          end
        end
        return list
      end

      def create_words_combo(user_input)
        # Creating words combos with_index
        # "Je suis ton " becomes { [0] => "Je", [0,1] => "Je suis", [0,1,2] => "Je suis ton", [1] => "suis", [1,2] => "suis ton", [2] => "ton"}
        words_combos = {}
        (0..user_input.split(/[\s\']/).length).to_a.combination(2).to_a.each do |index_combo|
          if index_combo[0] + 4 >= index_combo[1]
            words_combos[(index_combo[0]..index_combo[1]-1).to_a] = user_input.split(/[\s\']/)[index_combo[0]..index_combo[1]-1].join(" ")
          end
        end
        return words_combos
      end

      def is_number? string
        true if Float(string) rescue false
      end

      def compare_elements(string1, string2, indexes, level, key, append_list, saved_hash, rec_list)
        # We check the fuzz distance between two elements, if it's greater than the min_matching_level or the current best distance, this is the new recordman
        # We only compare with item_part before "|" if any delimiter is present
        if string2.nil? 
          return level, saved_hash, rec_list 
        else 
          item_to_match = clear_string(string2)
          distance = @@fuzzloader.getDistance(string1, item_to_match)
          if distance > level
            return distance, { :key => key, :name => string2, :indexes => indexes , :distance => distance}, append_list
          end
          return level, saved_hash, rec_list
        end 
      end

      def better_corrected_distance?(a,b, content)
        # When user says "Bouleytreau Verrier", should we match "Bouleytreau" or "Bouleytreau-Verrier" ? Correcting distance with length of item found
        if a[:key] == b[:key]
          return (true if a[:distance] >= b[:distance]) || false
        else
          # Finding the lenght of what matched for both elements
          len_a = content.split(/[\s\']/)[a[:indexes][0]..a[:indexes][-1]].join(" ").length
          len_b = content.split(/[\s\']/)[b[:indexes][0]..b[:indexes][-1]].join(" ").length
          # Multiply distance with exponential/70 => we favour longer elements even if match was lower
          aDist = a[:distance].to_f * Math.exp((len_a - len_b)/70.0)
          if aDist > b[:distance]
            return true
          else
            return false
          end
        end
      end

      def uniq_concat(array1, array2)
        # Concatenate two "recognized items" arrays, by making sure there's not 2 values with the same key
        new_array = array1.dup.map(&:dup)
        array2.each do |hash|
          unless key_duplicate?(new_array, hash)
            new_array.push(hash)
          end
        end
        return new_array
      end

      def find_iterator(item_type, parsed)
        # Returns correct array to iterate over, given what item_type we're looking for
        if item_type == :activity_variety
          iterator = Activity.select('distinct on (cultivation_variety) *')
        elsif item_type == :inputs
          # For Inputs, check if procedure comports inputs
          if Procedo::Procedure.find(parsed[:procedure]).parameters_of_type(:input).empty?
            iterator = [] 
          else 
            iterator = Matter.availables(at: parsed[:date].to_datetime).of_expression(Procedo::Procedure.find(parsed[:procedure]).parameters_of_type(:input).collect(&:filter).join(" or "))
          end
        elsif item_type == :crop_groups
          begin 
            iterator = CropGroup.all
          rescue 
            iterator = [] 
          end 
        elsif item_type == :financial_year 
          iterator = FinancialYear.all
        elsif item_type == :press
          iterator = Matter.availables(at: parsed[:date].to_datetime).can('press(grape)')
        elsif item_type == :workers
          iterator = Worker.availables(at: parsed[:date].to_datetime).each
        elsif item_type == :entities 
          iterator = Entity.all
        elsif item_type == :destination
          iterator = Matter.availables(at: parsed[:date].to_datetime).where("variety='tank'")
        elsif item_type == :cultivablezones 
          iterator = CultivableZone.all
        elsif item_type == :equipments
          iterator = Equipment.availables(at: parsed[:date].to_datetime)
        elsif item_type == :plant
          iterator = Plant.availables(at: parsed[:date].to_datetime)
        elsif item_type == :land_parcel
          iterator = LandParcel.availables(at: parsed[:date].to_datetime)
        elsif item_type == :cultivation
          iterator = Product.availables(at: parsed[:date].to_datetime).of_expression("is land_parcel or is plant")
        end
        iterator
      end 

      def find_name_attribute(item_type)
        # Returns correct attributes that display interesting name to iterate over, given what item_type we're looking for
        if item_type == :activity_variety
          attribute = :cultivation_variety_name
        elsif item_type == :entities
          attribute = :full_name
        elsif item_type == :financial_year
          attribute = :code 
        elsif [:workers, :crop_groups, :inputs, :press, :destination, :cultivablezones, :equipments, :plant, :land_parcel, :cultivation].include? (item_type)
          attribute = :name
        end
        attribute
      end 

      # Creates a Json for an option
      def optJsonify(label, text=label)
        {label: label,
          value: {
            input: {
              text: text
            }
          }
        }
      end 

      # Creates a dynamic options array that can be displayed as options to ibm
      def dynamic_options(sentence, options, description = "")
        optJson = {} 
        optJson[:description] = description
        optJson[:response_type] = "option"
        optJson[:title] = sentence
        optJson[:options] = options
        return [optJson]
      end 

      def find_ambiguity(parsed, content, level)
        # Find ambiguities in what's been parsed, ie items with close fuzzy match for the best words that matched
        ambiguities = []
        parsed.each do |key, reco|
          if @@user_specific_types.include?(key.to_sym)
            iterator = find_iterator(key.to_sym, parsed)
            reco.each do |anItem|
              unless anItem[:distance] == 1
                anItem_name = content.split(/[\s\']/)[anItem[:indexes][0]..anItem[:indexes][-1]].join(" ")
                ambiguity_check(anItem, anItem_name, level, ambiguities, iterator)
              end
            end
          end
        end
        return ambiguities
      end

      def ambiguity_check(item_hash, what_matched, level, ambiguities, iterator, min_level=0)
        # Method to check ambiguity about a specific item
        ambig = []
        # For each element of the iterator (ex : for crop_groups => CropGroup.all ), if distances is close (+/-level) to item that matched it's part of the ambiguity possibilities
        iterator.each do |product|
          if item_hash[:key] != product[:id] and (item_hash[:distance] - @@fuzzloader.getDistance(clear_string(product[:name]), clear_string(what_matched))).between?(min_level,level)
            ambig.push(optJsonify(product[:name], "{:key => #{product[:id]}, :name => \"#{product[:name]}\"}"))
          end
        end
        # If ambiguous items, we add the current chosen element this ambig, and an element with what_matched do display to the user which words cuased problems
        unless ambig.empty?
          ambig.push(optJsonify(item_hash[:name], "{:key => #{item_hash[:key]}, :name => \"#{item_hash[:name]}\"}"))
          optDescription = {level: level, id: item_hash[:key], match: what_matched}
          optSentence = I18n.t("duke.ambiguities.ask", item: what_matched)
          optJson = dynamic_options(optSentence, ambig, optDescription)
          ambiguities.push(optJson)
        end
        return ambiguities
      end 

      def clear_string(fstr)
        # Remove useless elements from user sentence
        useless_dic = [/\bnum(e|é)ro\b/, /n ?°/, /(#|-|_|\\)/]
        useless_dic.each do |rgx|
          fstr = fstr.gsub(rgx, "")
        end
        return fstr.gsub(/\s+/, " ").downcase.split(" | ").first
      end

      def key_duplicate?(list, saved_hash)
        # Is there a duplicate in the list ? + List we want to keep using. List Mutation allows us to persist modification
        # ie. No Duplicate -> false + current list, Duplicate -> Distance(+/-)=False/True + Current list (with/without duplicate)
        if not list.any? {|recon_element| recon_element[:key] == saved_hash[:key]}
          return false
        elsif not list.any? {|recon_element| recon_element[:key] == saved_hash[:key] and saved_hash[:distance] >= recon_element[:distance] }
          return true
        else
          item_to_remove = list.find {|hash| hash[:key] == saved_hash[:key]}
          list.delete(item_to_remove)
          return false
        end
      end

      def extract_user_specifics(user_input, parsed, level)
        # Function used for extracting specific elements of every type that's in parsed & @@user_specifics, with minimum matching % level from user_input
        # Find all types that we're gonna check, and their values
        original_level = level
        user_specifics = parsed.select{ |key, value| @@user_specific_types.include?(key.to_sym)}
        # finding iterators only once
        attributes = {}
        user_specifics.keys.each do |itemType| 
          attributes[itemType] = {iterator: find_iterator(itemType.to_sym, parsed), name_attribute: find_name_attribute(itemType.to_sym)}
        end 
        # Creating all combo_words from user_input
        create_words_combo(user_input).each do |index, combo|
          # A Hash containing :key, :name, :indexes, :distance,
          matching_element = nil 
          # A pointer, which will point to the list on which to add the matching element, if a match occurs, else points to nothing
          matching_list = nil  
          level = original_level
          user_specifics.keys.each do |itemType|
            attributes[itemType][:iterator].each do |item|
              # Check specifically for first name if worker
              if itemType == :workers
                level, matching_element, matching_list = compare_elements(combo, item[:name].split.first, index, level, item[:id], parsed[itemType], matching_element, matching_list)
              end
              level, matching_element, matching_list = compare_elements(combo, item.send(attributes[itemType][:name_attribute]), index, level, item[:id], parsed[itemType], matching_element, matching_list)
            end
          end
          # If we recognized something, we append it to the correct matching_list and we remove what matched from the user_input
          unless matching_element.nil?
            matching_list = add_to_recognized(matching_element, matching_list, user_specifics.values, user_input)
          end
        end
        puts "voici le parsed : #{parsed} \n\n\n\n\n"
        return parsed
      end

    end
  end
end
