module Duke
  module Skill
    class DukeIntervention < DukeArticle
      using Duke::Utils::DukeRefinements

      attr_accessor :procedure, :input, :ambiguities, :working_periods, :doer, :tool, :plant, :cultivation, :crop_groups, :land_parcel
      attr_reader :specific

      def initialize(**args)
        super()
        @input, @doer, @tool, @crop_groups = Array.new(4, DukeMatchingArray.new)
        @retry = 0
        @ambiguities = []
        @working_periods = []
        args.each do |key, value|
          instance_variable_set("@#{key}", value)
        end
        @description = @user_input.clone
      end

      # Parse every Intervention Parameters
      def parse_sentence
        extract_date_and_duration  # getting cleaned user_input and finding when it happened and how long it lasted
        tag_specific_targets  # Tag the specific types of targets for this intervention
        extract_user_specifics # Then extract every possible user_specifics elements form the sentence
        add_input_rate  # Look for a specified rate for the input, or attribute nil
        extract_intervention_readings  # extract_readings
        find_ambiguity # Look for ambiguities in what has been parsed
        @specific = parseable # Set specifics searched items to all
      end

      # Parse a specific item type, if user input isn't a button click
      # @param [String] sp : specific item type
      def parse_specific(specific)
        @description = @user_input.clone
        @user_input = @user_input.duke_clear
        @specific = if specific.to_sym.eql? :targets
                      tag_specific_targets
                    else
                      specific
                    end
        extract_user_specifics(duke_json: self.duke_json(@specific, :procedure, :date, :user_input))
        add_input_rate if specific.to_sym == :input
        find_ambiguity
      end

      # @param [Integer] value : Integer parsed by ibm
      def extract_number_parameter(value)
        val = super(value)
        @retry += 1 if val.nil?
        val
      end

      # Extract both date_and duration (Both information can be extract from same string)
      def extract_date_and_duration
        @user_input = @user_input.duke_clear
        input_clone = @user_input.clone
        extract_duration
        extract_date
        extract_wp_from_interval(input_clone)
        unless @working_periods.present?
          if input_clone.match(Duke::Utils::Regex.morning_hour)
            @duration = 60 if @duration.nil?
          elsif input_clone.match(Duke::Utils::Regex.afternoon_hour)
            @date = @date.change(hour: @date.hour+12)
            @duration = 60 if @duration.nil?
          elsif input_clone.match('matin')
            if duration.present?
              working_periods_attributes
              return
            else
              @working_periods =
              [
                {
                  started_at: @date.to_time.change(offset: @offset, hour: 8, min: 0),
                  stopped_at: @date.to_time.change(offset: @offset, hour: 12, min: 0)
                  }
                ]
            end
          elsif input_clone.match(Duke::Utils::Regex.afternoon)
            if @duration.present?
              working_periods_attributes
              return
            else
              @working_periods =
              [
                {
                  started_at: @date.to_time.change(offset: @offset, hour: 14, min: 0),
                  stopped_at: @date.to_time.change(offset: @offset, hour: 17, min: 0)
                  }
                ]
            end
          elsif not_current_time? && @duration.nil? # One hour duration if hour specified but no duration
            @duration = 60
          end
        end
        working_periods_attributes unless @working_periods.present?
      end

      # @param [String] istr
      def extract_wp_from_interval(istr = @user_input)
        istr.scan(Duke::Utils::Regex.hour_interval).to_a.each do |interval|
          start, ending = [extract_hour(interval.first), extract_hour(interval.first)].sort # Extract two hours from interval & sort it
          @date = @date.to_time.change(offset: @offset, hour: start.hour, min: start.min)
          @duration = ((ending - start)/60).to_i
          @working_periods.push(
            {
              started_at: @date,
              stopped_at: @date + @duration.minutes
              }
          )
        end
      end

      # Checks if HH:MM corresponds to Time.now.HH:MM
      def not_current_time?
        now = Time.now
        hour_diff = @date.change(year: now.year, month: now.month, day: now.day) - now
        hour_diff.abs > 300
      end

      private

        attr_accessor :retry

        # Intervention symbols of user_specifics parseable attributes
        # @returns Array of symbols
        def parseable
          [*super(), :input, :doer, :tool, :crop_groups, :plant, :cultivation, :land_parcel]
        end

        # @param [DukeIntervention] int : intervention to concatenate with it's specific attributes
        def concat_specific(int:)
          @ambiguities = int.ambiguities
          [int.specific].flatten.each do |var|
            new_var = DukeMatchingArray.new(arr: send(var).to_a + int.send(var).to_a)
            self.instance_variable_set("@#{var}", new_var.uniq_allow_ambiguity(@ambiguities))
          end
          self.update_description(int.description) unless btn_click_cancelled?(int.description)
        end

        # @returns json Option with all clickable buttons understandable by IBM
        def modification_candidates
          candidates = %i[tool doer input].select{|type| send(type).present?}
                                            .map{|type| optionify(I18n.t("duke.interventions.#{type}"))}
          candidates.push optionify(I18n.t('duke.interventions.temporality'))
          candidates.push optionify(I18n.t('duke.interventions.target')) if target?
          dynamic_options(I18n.t('duke.interventions.ask.what_modify'), candidates)
        end

        # Does this intervention have any target ?
        def target?
          @plant.present? || @crop_groups.present? || @cultivation.present? || @land_parcel.present?
        end

        # Create Sentence describing current intervention
        def speak_intervention
          procedo = Procedo::Procedure.find(@procedure)
          sentence = I18n.t("duke.interventions.ask.save_intervention_#{rand(0...3)}")
          sentence += "<br>&#8226 #{I18n.t('duke.interventions.intervention')} : #{Procedo::Procedure.find(@procedure).human_name}"
          if @crop_groups.to_a.present?
            sentence += "<br>&#8226 #{I18n.t('duke.interventions.group')} : #{@crop_groups.map(&:name).join(', ')}"
          end
          tar_type = procedo.parameters.find {|param| param.type == :target}
          if tar_type.present? && send(tar_type.name).to_a.present?
            sentence += "<br>&#8226 #{I18n.t("duke.interventions.#{tar_type.name}")} : #{send(tar_type.name).map(&:name).join(', ')}"
          end
          sentence += "<br>&#8226 #{I18n.t('duke.interventions.tool')} : #{@tool.map(&:name).join(', ')}" if @tool.to_a.present?
          sentence += "<br>&#8226 #{I18n.t('duke.interventions.doer')} : #{@doer.map(&:name).join(', ')}" if @doer.to_a.present?
          if @input.to_a.present?
            sentence += "<br>&#8226 #{I18n.t('duke.interventions.input')} : "
            @input.each do |input|
              sentence += "#{input.name} (#{input[:rate][:value].to_f} "
              if input[:rate][:unit].to_sym == :population
                sentence += "#{Matter.find_by_id(input.key)&.unit_name}), "
              else
                input_param = procedo.parameters_of_type(:input).find {|inp| Matter.find_by_id(input.key).of_expression(inp.filter)}
                sentence += "#{I18n.t("duke.interventions.units.#{input_param.handler(input[:rate][:unit]).unit.name}")}), "
              end
            end
          end
          @readings.each do |_key, rd|
            rd.to_a.each do |rd_hash|
              sentence += "<br>&#8226 #{I18n.t("duke.interventions.readings.#{rd_hash[:indicator_name]}")} : "
              if number?(rd_hash.values.last)
                sentence += rd_hash.values.last
              else
                sentence += I18n.t("duke.interventions.readings.#{rd_hash.values.last}")
              end
            end
          end
          sentence += "<br>&#8226 #{I18n.t('duke.interventions.date')} : #{@date.to_time.strftime('%d/%m/%Y')}"
          wp = @working_periods.sort_by{|wp| wp[:started_at]}
          sentence += "<br>&#8226 #{I18n.t('duke.interventions.working_period')} : #{wp.map do |wp|
                                                                                       I18n.t('duke.interventions.working_periods',
                                                                                              start: speak_hour(wp[:started_at]),
                                                                                              ending: speak_hour(wp[:stopped_at]))
                                                                                     end.join(', ')}"
          return sentence.gsub(/, <br>&#8226/, '<br>&#8226')
        end

        # @returns [String, Integer] Sentence to ask how much input, and input index inside @input
        def speak_input_rate
          @input.each_with_index do |input, index|
            if input[:rate][:value].nil?
              sentence = I18n.t("duke.interventions.ask.how_much_inputs_#{rand(0...2)}", input: input.name,
                                                                                        unit: Matter.find_by_id(input.key)&.unit_name)
              return sentence, index
            end
          end
        end

        # @params [DateTime.to_s] hour
        # @returns [String] Readable hour
        def speak_hour(hour)
          hour.to_time.min.positive? ? hour.to_time.strftime('%-Hh%M') : hour.to_time.strftime('%-Hh')
        end

        # Create instance_variable with tar_names
        def tag_specific_targets
          # Creates entry for each proc-specific target type with empty array inside what's about to be parsed
          tar_from_procedure.each do |target|
            self.instance_variable_set("@#{target}", DukeMatchingArray.new)
          end
        end

        # Check if readings exits, if so, and if extract_#{reading} method exitsts, try to extract it
        def extract_intervention_readings
          @readings = Hash[*Procedo::Procedure.find(@procedure).product_parameters(true).flat_map {|param|
  [param.type, DukeMatchingArray.new]}]
          Procedo::Procedure.find(@procedure).product_parameters(true).map(&:readings).reject(&:empty?).flatten.each do |reading|
            begin
              send("extract_#{reading.name}")
            rescue NoMethodError => e
              puts "#{e} readings extractor not created yet"
            end
          end
        end

        # Extract vine_pruning_system reading
        def extract_vine_pruning_system
          pruning_systems = {
            cordon_pruning: /(royat|cordon)/,
            formation_pruning: /formation/,
            gobelet_pruning: /gobelet/,
            guyot_double_pruning: /guyot.*(doub|mult)/,
            guyot_simple_pruning: /guyot/
          }
          pruning_systems.each do |name, regex|
            if @user_input.matchdel(regex)
              @readings[:target].push(
                {
                  indicator_name: :vine_pruning_system, indicator_datatype: :choice, choice_value: name.to_s
                }
              )
              break
            end
          end
        end

        # Extract vine stock bud charge reading
        def extract_vine_stock_bud_charge
          if charge = @user_input.match(Duke::Utils::Regex.bud_charge)
            @readings[:target].push(
              {
                indicator_name: :vine_stock_bud_charge, indicator_datatype: :integer, integer_value: charge[1]
              }
            )
          elsif sec_charge = @user_input.match(Duke::Utils::Regex.second_bud_charge)
            @readings[:target].push(
              {
                indicator_name: :vine_stock_bud_charge, indicator_datatype: :integer, integer_value: sec_charge[2]
              }
            )
          end
        end

        # Adds input rate to input DukeMatchingItem
        def add_input_rate
          @input.each_with_index do |input, _index|
            if quantity = @user_input.matchdel(Duke::Utils::Regex.input_quantity(input.matched))
              measure = get_measure(quantity[1].gsub(',', '.').to_f, quantity[4], (true unless quantity[6].nil?))
            elsif sec_quantity = @user_input.matchdel(Duke::Utils::Regex.second_input_quantity(input.matched))
              measure = get_measure(sec_quantity[2].gsub(',', '.').to_f, sec_quantity[5], (true unless sec_quantity[7].nil?))
            else # Associate a nil population rate if we don't find a quantity
              measure = get_measure(nil.to_f, :population, nil)
            end
            if input.measure_coherent?(measure, @procedure) # Check for coherent unit
              procedo_params = Procedo::Procedure.find(@procedure).parameters_of_type(:input)
              input_param = procedo_params.find do |param|
                Matter.find_by_id(input.key).of_expression(param.filter)
              end
              if measure.repartition_unit.nil? # If unit is area based
                measure = measure.in(input_param.handler("net_#{measure.base_dimension}").unit.name)
                input[:rate] =
                {
                  value: measure.value.to_f,
                  unit: "net_#{measure.base_dimension}"
                }
              else # If unit is not area based
                measure =  measure.in(input_param.handler(measure.dimension).unit.name)
                input[:rate] =
                {
                  value: measure.value.to_f,
                  unit: measure.dimension
                }
              end
            else # Otherwise, return a nil population rate, that the user will be ask to change
              input[:rate] =
              {
                value: nil,
                unit: :population
              }
            end
          end
        end

        # @params [Integer] value
        # @params [Unit] symbol
        # @params [Boolean] area
        # Returns [Measure]
        def get_measure(value, unit, area)
          if unit == :population
            return Measure.new(value, :population)
          elsif unit.match(/(kilo|kg)/)
            return Measure.new(value, 'kilogram') if area.nil?

            return  Measure.new(value, 'kilogram_per_hectare')
          elsif unit.match(/(gramme|g)/)
            return Measure.new(value, 'gram') if area.nil?

            return  Measure.new(value, 'gram_per_hectare')
          elsif unit.match(/(tonne)/) || unit == 't'
            return Measure.new(value, 'ton') if area.nil?

            return  Measure.new(value, 'ton_per_hectare')
          elsif unit.match(/(hectolitre|hl)/)
            return Measure.new(value, 'hectoliter') if area.nil?

            return  Measure.new(value, 'hectoliter_per_hectare')
          elsif unit.match(/(litre|l)/)
            return Measure.new(value, 'liter') if area.nil?

            return  Measure.new(value, 'liter_per_hectare')
          end
        end

        # @return [String, String, Hash|Array|Integer] what_next, sentence, optional
        def redirect
          if @retry == 2
            return :cancel
          elsif @ambiguities.present?
            return :ask_ambiguity, nil, @ambiguities.first
          elsif @input.to_a.any? {|input| input[:rate][:value].nil?}
            return :ask_input_rate, *speak_input_rate
          else
            return :save, speak_intervention
          end
        end

        def working_periods_attributes
          if @duration.nil? # Basic working_periods if duration.nil?:true
            @working_periods =
            [
              {
                started_at: @date.to_time.change(offset: @offset, hour: 8, min: 0),
                stopped_at: @date.to_time.change(offset: @offset, hour: 12, min: 0)
              },
              {
                started_at: @date.to_time.change(offset: @offset, hour: 14, min: 0),
                stopped_at: @date.to_time.change(offset: @offset, hour: 17, min: 0)
              }
            ]
          elsif @duration.is_a?(Integer) # Specific working_periods if a duration was found
            @working_periods =
            [
              {
                started_at: @date.to_time.change(offset: @offset),
                stopped_at: @date.to_time.change(offset: @offset) + @duration.to_i.minutes
              }
            ]
          end
        end

    end
  end
end
