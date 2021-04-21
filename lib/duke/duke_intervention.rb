module Duke
  class DukeIntervention < DukeArticle
    using Duke::DukeRefinements

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
      extract_procedure unless permitted_procedure_or_categorie?
    end

    # Create intervention from json
    # @param [Json] duke_json - Json representation of dukeIntervention
    # @param [Boolean] all - Should we recover everything, or only user_specifics
    # @returns DukeIntervention
    def recover_from_hash(duke_json, all = true)
      duke_json.slice(*parseable).each{|k, v| self.instance_variable_set("@#{k}", DukeMatchingArray.new(arr: v))}
      duke_json.except(*parseable).each{|k, v| self.instance_variable_set("@#{k}", v)} if all
      self
    end

    # @returns json Option with all clickable buttons understandable by IBM
    def modification_candidates
      candidates = %i[tool doer input].select{|type| send(type).present?}
                                         .map{|type| optJsonify(I18n.t("duke.interventions.#{type}"))}
      candidates.push optJsonify(I18n.t('duke.interventions.temporality'))
      candidates.push optJsonify(I18n.t('duke.interventions.target')) if target?
      return dynamic_options(I18n.t('duke.interventions.ask.what_modify'), candidates)
    end

    # @returns json Option with all clickable buttons understandable by IBM
    def complement_candidates
      procedo = Procedo::Procedure.find(@procedure)
      candidates = %i[target tool doer input].select{|type| procedo.parameters_of_type(type).present?}
                                                  .map{|type| optJsonify(I18n.t("duke.interventions.#{type}"))}
      candidates.push optJsonify(I18n.t('duke.interventions.working_period'))
      return dynamic_options(I18n.t('duke.interventions.ask.what_add'), candidates)
    end

    # @returns bln, is procedure_parseable?
    def ok_procedure?
      procedo = Procedo::Procedure.find(@procedure)
      procedo.present? && (procedo.activity_families & %i[vine_farming plant_farming]).any?
    end

    # @return json with next_step if procedure is not parseable
    def guide_to_procedure
      if @procedure.blank?
        suggest_procedure_from_blank
      elsif @procedure.is_a?(Hash)
        suggest_procedure_from_hash
      else
        suggest_procedure_from_string
      end
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

    # Parse a specific item type, if user can answer via buttons
    # @param [String] sp : specific item type
    def parse_specific_buttons(specific)
      if btn_click_response? @user_input # If response type matches a multiple click response
        products = btn_click_responses(@user_input).map do |id| # Creating a list with all chosen products
          Product.find_by_id id
        end
        products.each{|product| unless product.nil?
                                  send(specific).push DukeMatchingItem.new(name: product.name,
                                                                           key: product.id,
                                                                           distance: 1,
                                                                           matched: product.name)
                                end}
        add_input_rate if specific.to_sym == :input
        @specific = specific.to_sym
        @description = prods.map(&:name).join(', ')
      else
        parse_specific(specific)
      end
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

    # @param [DukeIntervention] int : intervention to concatenate with it's specific attributes
    def concat_specific(int:)
      @ambiguities = int.ambiguities
      [int.specific].flatten.each do |var|
        new_var = DukeMatchingArray.new(arr: send(var).to_a + int.send(var).to_a)
        self.instance_variable_set("@#{var}", new_var.uniq_allow_ambiguity(@ambiguities))
      end
      self.update_description(int.description) unless btn_click_cancelled?(int.description)
    end

    # @param [DukeIntervention] int : previous DukeIntervention
    def replace_specific(int:)
      specific_json = int.duke_json(int.specific, :ambiguities)
      self.recover_from_hash(self.duke_json.merge(specific_json))
      self.update_description(int.description)
    end

    # @param [DukeIntervention] int : previous DukeIntervention
    def join_temporality(int)
      self.update_description(int.description)
      if int.working_periods.size > 1 && int.duration.present?
        @working_periods = int.working_periods
        return
      elsif (int.date.to_date == @date.to_date || int.date.to_date != @date.to_date && int.date.to_date == Time.now.to_date)
        @date = @date.to_time.change(hour: int.date.hour, min: int.date.min) if int.not_current_time?
      elsif int.date.to_date != Time.now.to_date
        @date = @date.to_time.change(year: int.date.year, month: int.date.month, day: int.date.day)
        @date = @date.to_time.change(hour: int.date.hour, min: int.date.min) if int.not_current_time?
      end
      @duration = int.duration if int.duration.present? && (@duration.nil? || @duration.eql?(60) || !int.duration.eql?(60))
      working_periods_attributes
    end

    # @param [Array] periods : parsed Working_periods
    def add_working_interval(periods)
      if periods.nil?
        return
      else
        periods.each do |period|
          @working_periods.push(period) if @working_period.none?{ |wp|
            period[:started_at].between?(wp[:started_at], wp[:stopped_at]) || period[:stopped_at].between?(wp[:started_at], wp[:stopped_at])
          }
        end
      end
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
        if input_clone.match(/\b(00|[0-9]|1[0-1]) *(h|heure(s)?|:) *([0-5]?[0-9])?\b *(du|de|ce)? *matin/)
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
        elsif input_clone.match(/(apr(e|è)?s( |-)?midi|apr(e|è)m|apm)/)
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
    def extract_wp_from_interval(istr)
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

    # @param [String] type : Type of item for which we want to display all suggestions
    # @return [Json] OptJson for Ibm to display clickable buttons with every item & labels
    def all_options(type)
      pars = Procedo::Procedure.find(@procedure).parameters_of_type(type.to_sym).select do |param|
        Product.availables(at: @date.to_time).of_expression(param.filter).present?
      end
      items = pars.map do |param|
        [
          {
            global_label: param.human_name
          },
          Product.availables(at: @date.to_time).of_expression(param.filter)
        ]
      end
      items = items.flatten.reject do |prod| # Remove Already chosen from suggestions
        prod.respond_to?(:id) && send(type).any?{|reco| reco.key == prod.id}
      end
      options = items.map do |itm| # Turn it to Jsonified options
        itm.is_a?(Hash) ? itm : optJsonify(itm.name, itm.id)
      end
      if options.empty?
        dynamic_text(I18n.t('duke.interventions.ask.no_complement'))
      elsif options.size == 2
        dynamic_options(I18n.t('duke.interventions.ask.one_complement'), options)
      else
        dynamic_options(I18n.t("duke.interventions.ask.what_complement_#{type}"), options)
      end
    end

    # @returns [Integer] newly created intervention id
    def save_intervention
      intervention_params = {
        procedure_name: @procedure,
        description: "Duke : #{@description}",
        state: 'done',
        number: '50',
        nature: 'record',
        tools_attributes: tool_attributes.to_a,
        doers_attributes: doer_attributes.to_a,
        targets_attributes: target_attributes.to_a,
        inputs_attributes: input_attributes.to_a,
        working_periods_attributes: @working_periods
      }
      add_readings_attributes(intervention_params)
      it = Intervention.create!(intervention_params)
      return it.id
    end

    private

      attr_accessor :retry

      # Intervention symbols of user_specifics parseable attributes
      # @returns Array of symbols
      def parseable
        [*super(), :input, :doer, :tool, :crop_groups, :plant, :cultivation, :land_parcel]
      end

      # Does this intervention have any target ?
      def target?
        @plant.present? || @crop_groups.present? || @cultivation.present? || @land_parcel.present?
      end

      # Is the transmitted procedure accepted, or a category or an activity family
      def permitted_procedure_or_categorie?
        ok_procedure? or Onoma::ProcedureCategory.find(@procedure).present? or Onoma::ActivityFamily.find(@procedure).present?
      end

      # Extract procedure from user sentence
      def extract_procedure
        procs = Duke::DukeMatchingArray.new
        @user_input += " - #{@procedure}" if @procedure.present?
        @user_input = @user_input.duke_clear # Get clean string before parsing
        attributes =  [
                        [
                          :procedure,
                          {
                            iterator: procedure_iterator,
                            list: procs
                          }
                        ]
                      ]
        create_words_combo.each do |combo| # Creating all combo_words from user_input
          parser = DukeParser.new(word_combo: combo, level: 80, attributes: attributes) # create new DukeParser
          parser.parse # parse procedure
        end
        @procedure = procs.max.key if procs.present?
      end

      # Procedures iterator depending on user activity scope
      def procedure_iterator
        procedure_scope =
        [
          :common,
          if ekyagri?
            :vegetal
          else
            vegetal? ? :viti_vegetal : :viti
          end,
          animal? ? :animal : nil
        ]
        procedure_entities.slice(*procedure_scope).values.flatten
      end

      # Handles blank procedure accordingly
      def suggest_procedure_from_blank
        if (farming_type = exclusive_farming_type).present?
          suggest_categories_from_family(farming_type)
        else
          suggest_families_disambiguation
        end
      end

      # Handles string (not accepted procedure) accordingly
      def suggest_procedure_from_string
        procedo = Procedo::Procedure.find(@procedure)
        if Onoma::ActivityFamily.find(@procedure).present?
          suggest_categories_from_family(@procedure)
        elsif Onoma::ProcedureCategory.find(@procedure).present?
          suggest_procedures_from_category
        elsif procedo.present? && (procedo.activity_families & %i[vine_farming plant_farming]).empty?
          non_supported_redirect
        elsif @procedure.scan(/cancel/).present?
          cancel_redirect
        else
          not_understanding_redirect
        end
      end

      # Handles hash procedure (matched a category or an ambiguity) accordingly
      def suggest_procedure_from_hash
        if @procedure.key?(:categories)
          suggest_categories_disambiguation
        elsif @procedure.key?(:procedures)
          suggest_procedures_disambiguation
        elsif @procedure.key?(:category)
          @procedure = @procedure[:category]
          suggest_procedures_from_category
        end
      end

      # Suggest disambiguation to the user for his selected procedure
      # @returns json
      def suggest_procedures_disambiguation
        procs = @procedure[:procedures].map do |proc|
          label = Procedo::Procedure.find(proc[:name]).human_name
          label +=  " - Prod. #{proc[:family]}" if proc.key?(:family)
          optJsonify(label, proc[:name])
        end
        w_procedure_redirect(dynamic_options(I18n.t('duke.interventions.ask.which_procedure'), procs))
      end

      # Suggest disambiguation to the user for his selected category
      # @returns json
      def suggest_categories_disambiguation
        categories = @procedure[:categories].map do |cat|
          label = Onoma::ProcedureCategory.find(cat[:name]).human_name
          label += " - Prod. #{cat[:family]}" if cat.key?(:family)
          optJsonify(label, cat[:name])
        end
        w_procedure_redirect(dynamic_options(I18n.t('duke.interventions.ask.what_category'), categories))
      end

      # Suggest disambiguation to the user for the intervention family
      def suggest_families_disambiguation
        families = %i[plant_farming vine_farming].map do |fam|
          optJsonify(Onoma::ActivityFamily[fam].human_name, fam)
        end
        families += [optJsonify(I18n.t('duke.interventions.cancel'), :cancel)]
        w_procedure_redirect(dynamic_options(I18n.t('duke.interventions.ask.what_family'), families))
      end

      # Suggest procedures to the user for selected category
      def suggest_procedures_from_category
        procs = Procedo::Procedure.of_main_category(@procedure)
        procs.sort_by!(&:position) if procs.all?{|proc| defined?(proc.position)}
        procs.map! do |proc|
          optJsonify(proc.human_name.to_sym, proc.name)
        end
        w_procedure_redirect(dynamic_options(I18n.t('duke.interventions.ask.which_procedure'), procs))
      end

      # Suggest categories to the user for selected family
      def suggest_categories_from_family(family)
        categories = Onoma::ProcedureCategory.select do |cat|
          cat.activity_family.include?(family.to_sym) and Procedo::Procedure.of_main_category(cat).present?
        end
        categories = ListSorter.new(:procedure_categories, categories).sort if defined?(ListSorter)
        categories.map! do |cat|
          optJsonify(cat.human_name, cat.name)
        end
        w_procedure_redirect(dynamic_options(I18n.t('duke.interventions.ask.what_category'), categories))
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
        if tar_type.present? || send(tar_type.name).to_a.present?
          sentence += "<br>&#8226 #{I18n.t("duke.interventions.#{tar_type.name}")} : #{send(tar_type.name).map(&:name).join(', ')}"
        end
        sentence += "<br>&#8226 #{I18n.t('duke.interventions.tool')} : #{@tool.map(&:name).join(', ')}" if @tool.to_a.present?
        sentence += "<br>&#8226 #{I18n.t('duke.interventions.doer')} : #{@doer.map(&:name).join(', ')}" if @doer.to_a.present?
        if @input.to_a.present?
          sentence += "<br>&#8226 #{I18n.t('duke.interventions.input')} : "
          @input.each do |input|
            sentence += "#{input.name} (#{input[:rate][:value].to_f}"
            if input[:rate][:unit].to_sym == :population
              sentence += "#{Matter.find_by_id(input.key)&.unit_name})"
            else
              input_param = procedo.parameters_of_type(:input).find {|inp| Matter.find_by_id(input.key).of_expression(inp.filter)}
              sentence += I18n.t("duke.interventions.units.#{input_param.handler(input[:rate][:unit]).unit.name}")
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
          I18n.t('duke.interventions.working_periods', start: speak_hour(wp[:started_at]), ending: speak_hour(wp[:stopped_at]))
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
        if charge = @user_input.match(/(\d{1,2}) *(bourgeons|yeux|oeil)/)
          @readings[:target].push(
            {
              indicator_name: :vine_stock_bud_charge, indicator_datatype: :integer, integer_value: charge[1]
            }
          )
        elsif sec_charge = @user_input.match(/charge *(de|à|avec|a)? *(\d{1,2})/)
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
          return 'cancel'
        elsif @ambiguities.present?
          return 'ask_ambiguity', nil, @ambiguities.first
        elsif @input.to_a.any? {|input| input[:rate][:value].nil?}
          return 'ask_input_rate', speak_input_rate.flatten
        else
          return 'save', speak_intervention
        end
      end

      def w_procedure_redirect(options)
        {
          user_input: @description,
          redirect: :what_procedure,
          optional: options
        }
      end

      def non_supported_redirect
        {
          redirect: :non_supported_proc
        }
      end

      def cancel_redirect
        {
          redirect: :cancel
        }
      end

      def not_understanding_redirect
        {
          redirect: :not_understanding
        }
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

      # @params [hash] params : Intervention_parameters
      # Add readings to params_attributes
      def add_readings_attributes(params)
        @readings.delete_if{|_key, reading| reading.blank?}.each do |key, reading|
          params["#{key}s_attributes".to_sym].each do |attr|
            attr[:readings_attributes] = reading.map{|uniq_reading| ActiveSupport::HashWithIndifferentAccess.new(uniq_reading)}
          end
        end
      end

      # @return Array with target_attributes
      def target_attributes
        target_reference = Procedo::Procedure.find(@procedure).parameters.find {|param| param.type == :target}
        if target_reference.blank? || (send(target_reference.name).blank? && @crop_groups.blank?)
          []
        else
          targets = send(target_reference.name).map do |target|
            {
              reference_name: target_reference.name,
              product_id: target.key,
              working_zone: Product.find_by_id(target.key).shape
            }
          end
          groups = @crop_groups.map{|group| CropGroup.available_crops(group.key, 'is plant or is land_parcel')}.flatten.map do |crop|
            {
              reference_name: target_reference.name,
              product_id: crop.id,
              working_zone: Product.find_by_id(crop.id).shape
            }
          end
          (targets + groups).uniq{|t| t[:product_id]}
        end
      end

      # @return Array with input_attributes
      def input_attributes
        if @input.blank? || Procedo::Procedure.find(@procedure).parameters_of_type(:input).blank?
          []
        else
          @input.map do |input|
            {
              reference_name: input_reference_name(input.key),
              product_id: input.key,
              quantity_value: input.rate[:value].to_f,
              quantity_population: input.rate[:value].to_f,
              quantity_handler: input.rate[:unit]
            }
          end
        end
      end

      # @return Array with doer_attributes
      def doer_attributes
        if @doer.blank? || Procedo::Procedure.find(@procedure).parameters_of_type(:doer).blank?
          []
        else
          @doer.to_a.map do |worker|
            {
              reference_name: Procedo::Procedure.find(@procedure).parameters_of_type(:doer).first.name,
              product_id: worker.key
            }
          end
        end
      end

      # @return Array with tool_attributes
      def tool_attributes
        if @tool.blank? || Procedo::Procedure.find(@procedure).parameters_of_type(:tool).blank?
          []
        else
          @tool.to_a.map do |tool|
            {
              reference_name: tool_reference_name(tool.key),
              product_id: tool.key
            }
          end
        end
      end

      # @param [Integer] key: tool id
      # @return [String] tool reference_name
      def tool_reference_name(key)
        reference_name = Procedo::Procedure.find(@procedure).parameters_of_type(:tool).first.name
        Procedo::Procedure.find(@procedure).find_all{|param| param.type == :tool}.each do |tool_type|
          if Equipment.of_expression(tool_type.filter).include? Equipment.find_by_id(key)
            reference_name = tool_type
            break
          end
        end
        reference_name
      end

      # @param [Integer] key: input id
      # @return [String] input reference_name
      def input_reference_name(key)
        Procedo::Procedure.find(@procedure).parameters_of_type(:input).find {|inp| Matter.find_by_id(key).of_expression(inp.filter)}.name
      end

  end
end
