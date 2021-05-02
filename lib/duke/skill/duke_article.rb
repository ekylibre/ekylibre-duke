module Duke
  module Skill
    class DukeArticle
      using Duke::Utils::DukeRefinements
      include Duke::Utils::BaseDuke

      attr_accessor :date, :duration, :user_input, :description

      def initialize(**args)
        @description = ''
        @user_input = ''
        @date = Time.now
        @duration = 60
        args.each{|k, v| instance_variable_set("@#{k}", v)}
      end

      #  Create intervention from json
      #  @param [Json] duke_json - Json representation of dukeIntervention
      #  @param [Boolean] all - Should we recover everything, or only user_specifics
      #  @returns DukeIntervention
      def recover_from_hash(duke_json, all = true)
        duke_json.slice(*parseable).each{|k, v| self.instance_variable_set("@#{k}", DukeMatchingArray.new(arr: v))}
        duke_json.except(*parseable).each{|k, v| self.instance_variable_set("@#{k}", v)} if all
        self
      end

      #  @returns DukeIntervention to_json with given parameters
      def duke_json(*args)
        if args.empty?
          self.as_json.with_indifferent_access
        else
          args.flatten.map{|arg| [arg, self.send(arg)] if self.respond_to?(arg, true)}.compact.to_h.with_indifferent_access
        end
      end

      #  @param [json] duke_json : DukeArticle.as_json
      #  @param [Float] level : min_match_level
      #  Extract user specifics & recreates DukeArticle
      def extract_user_specifics(duke_json: self.duke_json, level: 80)
        @user_input = @user_input.duke_clear #  Get clean string before parsing
        user_specifics = duke_json.select{ |key, _value| parseable.include?(key.to_sym)}
        attributes = user_specifics.to_h do |key, list|
          [
            key,
            {
              iterator: iterator(key.to_sym),
              list: list
            }
          ]
        end
        create_words_combo.each do |combo| # Creating all combo_words from user_input
          parser = DukeParser.new(word_combo: combo, level: level, attributes: attributes) #  create new DukeParser
          parser.parse #  parse user_specifics
        end
        self.recover_from_hash(duke_json, false) # recreate DukeArticle
      end

      def update_description(ds)
        @description += " - #{ds}"
      end

      def reset_retries
        @retry = 0
      end

      #  Find ambiguities in what's been parsed
      def find_ambiguity
        self.as_json.each do |key, reco|
          if parseable.include?(key.to_sym)
            ambiguity_attr = ambiguities_attributes(key.to_sym)
            reco.each do |an_item|
              ambiguity = DukeAmbiguity.new(itm: an_item, ambiguity_attr: ambiguity_attr, itm_type: key).check_ambiguity
              @ambiguities.push(ambiguity) if ambiguity.present?
            end
          end
        end
      end

      #  @params [String] type : type of ambiguity to be corrected
      #  @params [Integer] key : key of ambiguous item
      def correct_ambiguity(type:, key:)
        current_hash = self.instance_variable_get("@#{type}").find_by_key(key)
        self.instance_variable_get("@#{type}").delete_one(current_hash)
        begin
          @user_input.split(/[|]{3}/).map{|chosen| eval(chosen)}.each do |chosen_one|
            chosen_one[:rate] = { unit: :population, value: nil } if current_hash.conflicting_rate?(chosen_one)
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

      #  Extracts date with correct hour from @user_input
      #  @return nil, but set @date
      def extract_date
        now = Time.now
        time = extract_hour(@user_input) # Extract hour from user_input
        if @user_input.matchdel(Duke::Utils::Regex.before_yesterday) #  Look for specific keywords
          d = Date.yesterday.prev_day
        elsif @user_input.matchdel('hier')
          d = Date.yesterday
        elsif @user_input.matchdel('demain')
          d = Date.tomorrow
        elsif full_date = @user_input.matchdel(Duke::Utils::Regex.full_date)
          @date = Time.new(year_from_str(full_date[4]), month_int(full_date[3]), full_date[1].to_i, time.hour, time.min, time.sec)
          return
        elsif slash_date = @user_input.matchdel(Duke::Utils::Regex.slash_date)
          @date = Time.new(year_from_str(slash_date[4]), slash_date[2].to_i, slash_date[1].to_i, time.hour, time.min, time.sec)
          return
        else #  If nothing matched, we return todays date
          @date = Time.new(now.year, now.month, now.day, time.hour, time.min, time.sec)
          return
        end
        @date = Time.new(d.year, d.month, d.day, time.hour, time.min, time.sec) #  Set correct time to date if match
        @offset = "+0#{Time.at(@date.to_time).utc_offset / 3600}:00"
      end

      private

        attr_accessor :retry, :tool, :cultivablezones, :offset

        def parseable
          %i[tool cultivablezones]
        end

        def to_ibm(**opt)
          redirection, sentence, options = redirect
          Duke::DukeResponse.new(parsed: self.duke_json, sentence: sentence, redirect: redirection, options: options, **opt)
        end

        #  Extracts duration from user_input
        #  @return nil but set @duration in minutes
        def extract_duration
          if @user_input.matchdel("trois quarts d'heure") #  Look for non-numeric values
            @duration = 45
            return
          elsif @user_input.matchdel("quart d'heure")
            @duration = 15
            return
          elsif @user_input.matchdel('demi heure')
            @duration = 30
            return
          end
          delta_in_mins = 0
          if min_time = @user_input.matchdel(Duke::Utils::Regex.minutes) #  Extract MM regex
            delta_in_mins += min_time[0].to_i
          elsif hour_min_time = @user_input.matchdel(Duke::Utils::Regex.hours_minutes) #  Extract HH:MM regex
            delta_in_mins += hour_min_time[2].to_i*60 + hour_min_time[4].to_i
          elsif hour_time = @user_input.matchdel(Duke::Utils::Regex.hours) #  Extract HH: regex
            delta_in_mins += hour_time[2].to_i*60
            delta_in_mins += 30 if @user_input.matchdel('et demi') #  Check for "et demi" in user_input
          else
            delta_in_mins = nil #  Set duration to nil on default
          end
          @duration = delta_in_mins
        end

        #  @param [String] content
        #  @return Datetime
        def extract_hour(content = @user_input)
          now = Time.now
          time = content.matchdel(Duke::Utils::Regex.time) #  matching time regex
          if time
            mins = time[4].nil? ? 0 : time[4].to_i
            Time.new(now.year, now.month, now.day, time[1].to_i, mins, 0)
          else
            {
              8 => 'matin',
              14 => 'après-midi',
              12 => 'midi',
              20 => 'soir',
              0 => 'minuit'
            }.each do |hour, val|
              return Time.new(now.year, now.month, now.day, hour, 0, 0) if content.matchdel(val)
            end
            Time.now #  If nothing matches, we return current hour
          end
        end

        #  @return [Datetime(start), Datetime(end)]
        def extract_time_interval
          now = Time.now
          since_date = @user_input.matchdel(Duke::Utils::Regex.since_date)
          since_slash_date = @user_input.matchdel(Duke::Utils::Regex.since_slash_date)
          since_month_date = @user_input.matchdel(Duke::Utils::Regex.since_month_date)
          if @user_input.matchdel('ce mois')
            return Time.new(now.year, now.month, 1, 0, 0, 0), now
          elsif @user_input.matchdel('cette semaine')
            return now - (now.wday - 1), now
          elsif since_date
            return Time.new(year_from_str(since_date[5]), month_int(since_date[4]), since_date[3].to_i, 0, 0, 0), now
          elsif since_slash_date
            return Time.new(year_from_str(since_slash_date[6]), since_slash_date[4].to_i, since_slash_date[3].to_i, 0, 0, 0), now
          elsif since_month_date
            year = (month > now.month) ? now.year - 1 : now.year
            return Time.new(year, month_int(since_month_date[3]), 1, 0, 0, 0), now
          else
            return Time.new(now.year, 1, 1, 0, 0, 0), now
          end
        end

        #  @param [Str|Integer|Float] year
        #  @return [Integer] parsed year
        def year_from_str(year)
          now = Time.now
          if year.to_i.between?(now.year - 2005, now.year - 1999)
            2000 + year.to_i
          elsif year.to_i.between?(now.year - 5, now.year + 1)
            year.to_i
          else
            now.year
          end
        end

        #  @param [String] month
        #  @return [Integer] month
        def month_int(month)
          hash =
          {
            janvier: 1, jan: 1, février: 2, fev: 2, fevrier: 2, mars: 3, avril: 4, avr: 4, mai: 5, juin: 6, juillet: 7, juil: 7, août: 8,
            aou: 8, aout: 8, septembre: 9, sept: 9, octobre: 10, oct: 10, novembre: 11, nov: 11, décembre: 12, dec: 12, decembre: 12
          }
          hash[month]
        end

        #  @param [Integer] value : Integer extracted by ibm
        #  @return [Stringified float or integer] || [nilType]
        def extract_number_parameter(value)
          match_to_float = @user_input.match(Duke::Utils::Regex.int_to_float(value)) unless value.nil? # check for float from watson int
          numbers = @user_input.match(Duke::Utils::Regex.up_to_four_digits_float) # check for number inside user_input
          if value.nil?
            value = numbers[0].gsub(',', '.').gsub(' ', '') if numbers
            return nil unless numbers
          elsif match_to_float
            value = match_to_float[0]
          end
          value.to_s.gsub(',', '.') #  returning value as a string
        end

        #  Choose between new_date & @date
        def choose_date(new_date)
          @date = new_date if (new_date.to_time - Time.now).abs > 300
        end

        #  Choose between new_duration and @duration
        def choose_duration(new_duration)
          @duration = new_duration unless new_duration.is_a?(Array) && new_duration.size.eql?(2)
        end

        #  @returns { [0]: "Je", [0,1]: "Je suis", [0,1,2]: "Je suis ton", [1]: "suis", [1,2]: "suis ton", [2]: "ton"} for "Je suis ton"
        def create_words_combo
          idx_cb = (0..@user_input.duke_words.size).to_a.combination(2)
          idx_cb.map{|i1, i2| [(i1..i2-1).to_a, @user_input.duke_words[i1..i2-1].join(' ')] if 4>= i2 - i1}.compact.to_h
        end

        #  @return true if there's nothing to iterate over
        def empty_iterator?(item_type)
          if item_type == :input && Procedo::Procedure.find(@procedure).parameters_of_type(:input).empty?
            true
          else
            item_type == :crop_groups && (defined? CropGroup).nil?
          end
        end

        # @return target_type given procedure_family
        def tar_from_procedure
          return Procedo::Procedure.find(@procedure).parameters.find {|param| param.type == :target}.name, :crop_groups
        end

        #  @param [str] item_type
        #  @return item iname_attr for this item
        def name_attr(item_type)
          attrs = {
            activity_variety: :cultivation_variety_name,
            entity: :full_name,
            financial_year: :code
          }
          if attrs.key? item_type
            attrs[item_type]
          else
            :name
          end
        end

        #  @param [str] item_type
        #  @return iterator for this item
        def iterator(item_type)
          name_attr = name_attr(item_type)
          if empty_iterator?(item_type)
            iterator = []
          elsif item_type == :account
            iterator = Account.all
          elsif item_type == :journal
            iterator = Journal.all
          elsif item_type == :depreciable
            iterator = Product.depreciables
          elsif item_type == :fixed_asset
            iterator = Product.find(FixedAsset.all.collect(&:product_id))
          elsif item_type == :bank_account
            iterator = Cash.all
          elsif item_type == :registered_phyto
            iterator = RegisteredPhytosanitaryProduct.all
          elsif item_type == :input
            expression = Procedo::Procedure.find(@procedure).parameters_of_type(:input).collect(&:filter).join(' or ')
            iterator = Matter.availables(at: @date.to_time).of_expression(expression)
          elsif item_type == :crop_groups
            iterator = CropGroup.all
          elsif item_type == :financial_year
            iterator = FinancialYear.all
          elsif item_type == :activity_variety
            iterator = Activity.select('distinct on (cultivation_variety) *')
          elsif item_type == :press
            iterator = Matter.availables(at: @date.to_time).can('press(grape)', 'press(juice)', 'press(fermented_juice)', 'press(wine)')
          elsif item_type == :doer
            iterator = Worker.availables(at: @date.to_time).each
          elsif item_type == :entity
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
            iterator = Product.availables(at: @date.to_time).of_expression('is land_parcel or is plant')
          end
          return iterator.map{|rec| { id: rec.id, partials: rec.send(name_attr).duke_clear.words_combinations, name: rec.send(name_attr) }}
        end

        #  @param [str] item_type
        #  @return Array of Arrays with each type, and it's iterator & name_attr
        def ambiguities_attributes(item_type)
          type =  if %i[crop_groups plant land_parcel cultivation].include?(item_type) && @procedure.present?
                    @procedure.present? ? tar_from_procedure : %i[plant crop_groups]
                  else
                    [item_type]
                  end
          return type.map{|ty| [ty, iterator(ty)]}
        end

    end
  end
end
