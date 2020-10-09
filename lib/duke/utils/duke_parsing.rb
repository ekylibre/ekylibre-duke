module Duke
  module Utils
    class DukeParsing
      @@fuzzloader = FuzzyStringMatch::JaroWinkler.create( :pure )

      def extract_duration(content)
          #Function that finds the duration of the intervention & converts this value in minutes using regexes to have it stored into Ekylibre
          delta_in_mins = 0
          regex = '\d+\s(\w*minute\w*|mins)'
          regex2 = '(de|pendant|durée) *(\d)\s?(heures|h|heure)\s?(\d\d)'
          regex3 = '(de|pendant|durée) *(\d)\s?(h\b|h\s|heure)'
          if content.include? "trois quarts d'heure"
            content["trois quart d'heure"] = ""
            return 45, content.strip.gsub(/\s+/, " ")
          end
          if content.include? "quart d'heure"
            content["quart d'heure"] = ""
            return 15, content.strip.gsub(/\s+/, " ")
          end
          if content.include? "demi heure"
            content["demi heure"] = ""
            return 30, content.strip.gsub(/\s+/, " ")
          end
          min_time = content.match(regex)
          if min_time
            delta_in_mins += min_time[0].to_i
            content[min_time[0]] = ""
            return delta_in_mins, content.strip.gsub(/\s+/, " ")
          end
          hour_min_time = content.match(regex2)
          if hour_min_time
            delta_in_mins += hour_min_time[2].to_i*60
            delta_in_mins += hour_min_time[4].to_i
            content[hour_min_time[0]] = ""
            return delta_in_mins, content.strip.gsub(/\s+/, " ")
          end
          hour_time = content.match(regex3)
          if hour_time
            delta_in_mins += hour_time[2].to_i*60
            content[hour_time[0]] = ""
            if content.include? "et demi"
              delta_in_mins += 30
              content["et demi"] = ""
            end
            return delta_in_mins, content.strip.gsub(/\s+/, " ")
          end
          return 60, content.strip.gsub(/\s+/, " ")
      end

      def extract_date(content)
        # Extract date from a string, and returns a dateTime object with appropriate date & time
        # Default value is Datetime.now
        now = DateTime.now
        month_hash = {"janvier" => 1, "février" => 2, "fevrier" => 2, "mars" => 3, "avril" => 4, "mai" => 5, "juin" => 6, "juillet" => 7, "août" => 8, "aout" => 8, "septembre" => 9, "octobre" => 10, "novembre" => 11, "décembre" => 12, "decembre" => 12 }
        full_date_regex = '(\d|\d{2})\s(janvier|février|fevrier|mars|avril|mai|juin|juillet|aout|août|septembre|octobre|novembre|décembre|decembre)(\s\d{4}|\s\b)'
        time, content = extract_hour(content)
        # Search for keywords
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
          # Then search for full date
          full_date = content.match(full_date_regex)
          if full_date
            content[full_date[0]] = ""
            day = full_date[1].to_i
            month = month_hash[full_date[2]]
            if full_date[3].to_i.between?(2015, 2021)
              year = full_date[3].to_i
            else
              year = Date.today.year
            end
            return DateTime.new(year, month, day, time.hour, time.min, time.sec), content.strip.gsub(/\s+/, " ")
          else
            return DateTime.new(now.year, now.month, now.day, time.hour, time.min, time.sec),  content.strip.gsub(/\s+/, " ")
          end
        end
        return DateTime.new(d.year, d.month, d.day, time.hour, time.min, time.sec), content.strip.gsub(/\s+/, " ")
      end

      def extract_hour(content)
        # Extract hour from a string, returns a DateTime object with appropriate date
        # Default value is Time.now
        now = DateTime.now
        time_regex = '\b(00|[0-9]|1[0-9]|2[03]) *(h|heure(s)?|:) *([0-5]?[0-9])?\b'
        time = content.match(time_regex)
        if time
          if time[4].nil?
            content[time[0]] = ""
            return DateTime.new(now.year, now.month, now.day, time[1].to_i, 0, 0), content
          else
            content[time[0]] = ""
            return DateTime.new(now.year, now.month, now.day, time[1].to_i, time[4].to_i, 0), content
          end
        elsif content.include? "matin"
          content["matin"] = ""
          return DateTime.new(now.year, now.month, now.day, 10, 0, 0), content
        elsif content.include? "après-midi"
          content["après-midi"] = ""
          return DateTime.new(now.year, now.month, now.day, 17, 0, 0), content
        elsif content.include? "midi"
          content["midi"] = ""
          return DateTime.new(now.year, now.month, now.day, 12, 0, 0), content
        elsif content.include? "soir"
          content["soir"] = ""
          return DateTime.new(now.year, now.month, now.day, 20, 0, 0), content
        elsif content.include? "minuit"
          content["minuit"] = ""
          return DateTime.new(now.year, now.month, now.day, 0, 0, 0), content
        else
          return DateTime.now, content
        end
      end

      def extract_number_parameter(value, content)
        match_to_float = content.match(/#{value}(\.\d{1,2})/) unless value.nil?
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
        return value.to_s.gsub(',','.')
      end

      def choose_date(date1, date2)
        #Date.now is the default value, so if the value returned is more than 15 away from now, we select it
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
        #If no element inside any of the lists has the same words used to match an element (overlapping indexes)
        if not all_lists.any? {|aList| aList.any? {|recon_element| !(recon_element[:indexes] & saved_hash[:indexes]).empty?}}
          hasDuplicate, list = key_duplicate?(list, saved_hash)
          unless hasDuplicate
            list.push(saved_hash)
          end
        # Else if one or multiple elements uses the same words -> if the distance is greater for this hash -> Remove other ones and add this one
        elsif not all_lists.any? {|aList| aList.any? {|recon_element| !(recon_element[:indexes] & saved_hash[:indexes]).empty? and !better_corrected_distance?(saved_hash, recon_element, content)}}
          # Check for duplicates in the list, if clear : -> remove value from any list with indexes overlapping and add current match to our list
          hasDuplicate, list = key_duplicate?(list, saved_hash)
          unless hasDuplicate
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
        # "Je suis ton " becomes { [0] => "Je", [0,1] => "Je suis", [0,1,2] => "Je suis ton", [1] => "suis", [1,2] => "suis ton", [2] => "ton"}
        words_combos = {}
        (0..user_input.split().length).to_a.combination(2).to_a.each do |index_combo|
          if index_combo[0] + 4 >= index_combo[1]
            words_combos[(index_combo[0]..index_combo[1]-1).to_a] = user_input.split()[index_combo[0]..index_combo[1]-1].join(" ")
          end
        end
        return words_combos
      end

      def compare_elements(string1, string2, indexes, level, key, append_list, saved_hash, rec_list)
          # We check the fuzz distance between two elements, if it's greater than the min_matching_level or the current best distance, this is the new recordman
          # We only compare with item_part before "|"
          item_to_match = clear_string(string2).split(" | ")[0]
          distance = @@fuzzloader.getDistance(string1, item_to_match)
          if distance > level
            return distance, { :key => key, :name => string2, :indexes => indexes , :distance => distance}, append_list
          end
          return level, saved_hash, rec_list
      end

      def better_corrected_distance?(a,b, content)
        # When user says "Bouleytreau Verrier", should we match "Bouleytreau" or "Bouleytreau-Verrier" ? Correcting distance with length of item found
        if a[:key] == b[:key]
          return (true if a[:distance] >= b[:distance]) || false
        else
          len_a = content.split()[a[:indexes][0]..a[:indexes][-1]].join(" ").split("").length
          len_b = content.split()[b[:indexes][0]..b[:indexes][-1]].join(" ").split("").length
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
          hasDuplicate, new_array = key_duplicate?(new_array, hash)
          unless hasDuplicate
            new_array.push(hash)
          end
        end
        return new_array
      end

      def find_ambiguity(parsed, content)
        # Find ambiguities in what's been parsed, ie items with close fuzzy match for the best words that matched
        ambiguities = []
        parsed.each do |key, reco|
          if [:targets, :destination, :crop_groups, :equipments, :workers, :inputs, :press].include?(key)
            reco.each do |anItem|
              unless anItem[:distance] == 1
                ambig = []
                anItem_name = content.split()[anItem[:indexes][0]..anItem[:indexes][-1]].join(" ")
                if key == :targets
                  iterator = Plant.availables(at: parsed[:date])
                elsif key == :destination
                  iterator = Matter.availables(at: parsed[:date]).where("variety='tank'")
                elsif key == :equipments
                  iterator = Equipment.availables(at: parsed[:date])
                elsif key == :inputs
                  iterator = Matter.availables(at: parsed[:date]).where("nature_id=45")
                elsif key == :workers
                  iterator = Worker.availables(at: parsed[:date]).each
                elsif key == :crop_groups
                  iterator = CropGroup.all.where("target = 'plant'")
                elsif key == :press
                  iterator = Matter.availables(at: parsed[:date]).can('press(grape)')
                end
                iterator.each do |product|
                  if anItem[:key] != product[:id] and (anItem[:distance] - @@fuzzloader.getDistance(clear_string(product[:name]), clear_string(anItem_name))).between?(0,0.02)
                    ambig.push({"key" => product[:id].to_s, "name" => product[:name]})
                  end
                end
                unless ambig.empty?
                  ambig.push({"key" => anItem[:key].to_s, "name" => anItem[:name]})
                  ambig.push({"key" => "inSentenceName", "name" => anItem_name})
                  # Only save ambiguities between max 7 elements
                  ambiguities.push(ambig.drop((ambig.length - 9 if ambig.length - 9 > 0 ) || 0))
                end
              end
            end
          end
        end
        return ambiguities
      end

      def clear_string(fstr)
        useless_dic = [/\bnum(e|é)ro\b/, /n ?°/, /(#|-|_|\\)/]
        useless_dic.each do |rgx|
          fstr = fstr.gsub(rgx, "")
        end
        return fstr.gsub(/\s+/, " ").downcase
      end

      def key_duplicate?(list, saved_hash)
        # Is there a duplicate in the list ? + List we want to keep using. List Mutation allows us to persist modification
        # -> No Duplicate : false + current list, Duplicate -> Distance(+/-)=False/True + Current list (with/without duplicate)
        if not list.any? {|recon_element| recon_element[:key] == saved_hash[:key]}
          return false, list
        elsif not list.any? {|recon_element| recon_element[:key] == saved_hash[:key] and saved_hash[:distance] >= recon_element[:distance] }
          return true, list
        else
          item_to_remove = list.find {|hash| hash[:key] == saved_hash[:key]}
          list.delete(item_to_remove)
          return false, list
        end
      end

      def extract_user_specifics(user_input, parsed)
        iterators_dic = {:workers => Worker.availables(at: parsed[:date]),
                         :equipments => Equipment.availables(at: parsed[:date]),
                         :inputs =>(Matter.availables(at: parsed[:date]).where("nature_id=45")  if parsed[:procedure] and !Procedo::Procedure.find( parsed[:procedure]).parameters_of_type(:input).empty?) || [],
                         :crop_groups => CropGroup.all,
                         :destination => Matter.availables(at: parsed[:date]).where("variety='tank'"),
                         :targets => Plant.availables(at: parsed[:date]),
                         :press => Matter.availables(at: parsed[:date]).can('press(grape)')}
        user_specifics = parsed.select{ |key, value| iterators_dic.key?(key)}
        create_words_combo(user_input).each do |index, combo|
          level = 0.89
          matching_element = nil # A Hash containing :key, :name, :indexes, :distance,
          matching_list = nil  # A pointer, which will point to the list on which to add the matching element, if a match occurs, else points to nothing
          user_specifics.keys.each do |itemType|
            iterators_dic[itemType].each do |item|
              if itemType == :workers
                level, matching_element, matching_list = compare_elements(combo, item[:name].split[0], index, level, item[:id], parsed[itemType], matching_element, matching_list)
              end
              level, matching_element, matching_list = compare_elements(combo, item[:name], index, level, item[:id], parsed[itemType], matching_element, matching_list)
            end
          end
          # If we recognized something, we append it to the correct matching_list and we remove what matched from the user_input
          unless matching_element.nil?
            matching_list = add_to_recognized(matching_element, matching_list, user_specifics.values, user_input)
          end
        end
      end

    end
  end
end
