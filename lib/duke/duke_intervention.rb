module Duke
  class DukeIntervention < DukeArticle
    using Duke::DukeRefinements

    attr_accessor :procedure, :input, :ambiguities, :working_periods, :doer, :tool, :plant, :cultivation, :crop_groups, :land_parcel
    attr_reader :specific

    def initialize(**args)
      super()
      @procedure = nil
      @input, @doer, @tool, @crop_groups = Array.new(4, DukeMatchingArray.new)
      @retry = 0
      @ambiguities, @working_periods = [], []
      args.each{|k, v| instance_variable_set("@#{k}", v)}
      @description = @user_input.clone
      @matchArrs.concat([:input, :doer, :tool, :crop_groups, :plant, :cultivation, :land_parcel])
      extract_procedure unless permitted_procedure_or_categorie?
    end 

    # @creates intervention from json
    # @param [Json] jsonD - Json representation of dukeIntervention
    # @param [Boolean] all - Should we recover everything, or only user_specifics
    # @returns DukeIntervention
    def recover_from_hash(jsonD, all=true) 
      jsonD.slice(*@matchArrs).each{|k,v| self.instance_variable_set("@#{k}", DukeMatchingArray.new(arr: v))}
      jsonD.except(*@matchArrs).each{|k,v| self.instance_variable_set("@#{k}", v)} if all
      self
    end 

    # @returns json Option with all clickable buttons understandable by IBM
    def modification_candidates
      candidates = [:tool, :doer, :input].select{|type| self.instance_variable_get("@#{type}").present? }
                                         .map{|type| optJsonify(I18n.t("duke.interventions.#{type}"))}
      candidates.push(optJsonify(I18n.t("duke.interventions.temporality")))
      candidates.push(optJsonify(I18n.t("duke.interventions.target"))) if @plant.present?||@crop_groups.present?||@cultivation.present?||@land_parcel.present?
      return dynamic_options(I18n.t("duke.interventions.ask.what_modify"), candidates)
    end 

    # @returns json Option with all clickable buttons understandable by IBM
    def complement_candidates 
      candidates = [:target, :tool, :doer, :input].select{|type| Procedo::Procedure.find(@procedure).parameters.find {|param| param.type == type}.present?}
                                                  .map{|type| optJsonify(I18n.t("duke.interventions.#{type}"))}
      candidates.push(optJsonify(I18n.t("duke.interventions.working_period")))
      return dynamic_options(I18n.t("duke.interventions.ask.what_add"), candidates)
    end 

    # @returns bln, is procedure_parseable?
    def ok_procedure? 
      procedo = Procedo::Procedure.find(@procedure)
      procedo.present? && (procedo.activity_families & [:vine_farming, :plant_farming]).any?
    end 
    
    # @return json with next_step if procedure is not parseable
    def guide_to_procedure
      if @procedure.blank?
        suggest_procedure_from_blank
      elsif @procedure.kind_of?(Hash)
        suggest_procedure_from_hash
      else
        suggest_procedure_from_string 
      end
    end 

    # Parse every Intervention Parameters
    def parse_sentence
      extract_date_and_duration  # getting cleaned user_input and finding when it happened and how long it lasted
      tag_specific_targets  # Tag the specific types of targets for this intervention
      extract_user_specifics  # Then extract every possible user_specifics elements form the sentence (here : input, doer, tool, targets)
      add_input_rate  # Look for a specified rate for the input, or attribute nil
      extract_intervention_readings  # extract_readings 
      find_ambiguity # Look for ambiguities in what has been parsed
      @specific = @matchArrs # Set specifics searched items to all
    end 

    # Parse a specific item type, if user can answer via buttons
    # @param [String] sp : specific item type
    def parse_specific_buttons sp 
      if @user_input.match(/^(\d{1,5}(\|{3}|\b))*$/) # If response type matches a multiple click response
        prods = @user_input.split(/\|{3}/).map{|num| Product.find_by_id(num.to_i)}  # Creating a list with all chosen products
        prods.each{|prod| self.instance_variable_get("@#{sp}").push(DukeMatchingItem.new(name: prod.name, key: prod.id, distance: 1, matched: prod.name)) unless prod.nil?}
        add_input_rate if sp.to_sym == :input 
        @specific = sp.to_sym
        @description = prods.map{|prod| prod.name}.join(", ")
      else
        parse_specific(sp)
      end 
    end 
    
    # Parse a specific item type, if user input isn't a button click
    # @param [String] sp : specific item type 
    def parse_specific(sp)
      get_clean_sentence
      @specific = (tag_specific_targets if sp.to_sym.eql?(:targets))||sp
      extract_user_specifics(jsonD: self.to_jsonD(@specific, :procedure, :date, :user_input), level: 80)
      add_input_rate if sp.to_sym == :input 
      find_ambiguity
    end 

    # @param [DukeIntervention] int : intervention to concatenate with it's specific attributes
    def concat_specific(int:)
      @ambiguities = int.ambiguities
      [int.specific].flatten.each do |var| 
        self.instance_variable_set("@#{var}", DukeMatchingArray.new(arr: (self.instance_variable_get("@#{var}").to_a + int.instance_variable_get("@#{var}").to_a)).uniq_allow_ambiguity(@ambiguities))
      end
      self.update_description(int.description) unless int.description.eql?("*cancel*")
    end 

    # @param [DukeIntervention] int : previous DukeIntervention 
    def replace_specific(int:)
      full_jsonD = self.to_jsonD.merge(int.to_jsonD(int.specific, :ambiguities))
      self.recover_from_hash(full_jsonD)
      self.update_description(int.description)
    end 

    # @param [DukeIntervention] int : previous DukeIntervention
    def join_temporality(int)
      self.update_description(int.description)
      (@working_periods = int.working_periods; return) if int.working_periods.size > 1 && int.duration.present? 
      if (int.date.to_date === @date.to_date||int.date.to_date != @date.to_date && int.date.to_date === Time.now.to_date)
        @date = @date.to_time.change(hour: int.date.hour, min: int.date.min) if int.not_current_time? 
      elsif int.date.to_date != Time.now.to_date 
        @date = @date.to_time.change(year: int.date.year, month: int.date.month, day: int.date.day)
        @date = @date.to_time.change(hour: int.date.hour, min: int.date.min) if int.not_current_time?
      end 
      @duration = int.duration if int.duration.present? && (@duration.nil?||(@duration.eql?(60)||!int.duration.eql?(60)))
      working_periods_attributes
    end 

    # @param [Array] periods : parsed Working_periods
    def add_working_interval(periods) 
      return if periods.nil? 
      periods.each do |period| 
        @working_periods.push(period) unless @working_periods.any?{|wp|period[:started_at].between?(wp[:started_at], wp[:stopped_at])||period[:stopped_at].between?(wp[:started_at], wp[:stopped_at])}
      end 
    end 

    # @param [Integer] value : Integer parsed by ibm
    def extract_number_parameter(value)
      val = super(value) 
      @retry += 1 if val.nil? 
      val 
    end 

    # Extract both date_and duration (Both information can be extract from same string)
    def extract_date_and_duration
      @user_input = @user_input.duke_clear
      input_clone = @user_input.clone 
      extract_duration
      extract_date
      extract_wp_from_interval(input_clone)
      unless @working_periods.present?
        if input_clone.match(/\b(00|[0-9]|1[0-1]) *(h|heure(s)?|:) *([0-5]?[0-9])?\b *(du|de|ce)? *matin/)
          @duration = 60 if @duration.nil?
        elsif input_clone.match(/\b(00|[0-9]|1[0-1]) *(h|heure(s)?|:) *([0-5]?[0-9])?\b *(du|de|cet|cette)? *(le|l')? *(aprem|apm|après-midi|apres midi|après midi|aprèm)/)
          @date = @date.change(hour: @date.hour+12)
          @duration = 60 if @duration.nil? 
        elsif input_clone.match("matin") 
          (working_periods_attributes; return) if @duration.present? 
          @working_periods = [{started_at: @date.to_time.change(offset: @offset, hour: 8, min: 0), stopped_at: @date.to_time.change(offset: @offset, hour: 12, min: 0)}]
        elsif input_clone.match(/(apr(e|è)?s( |-)?midi|apr(e|è)m|apm)/)
          (working_periods_attributes; return) if @duration.present?
          @working_periods = [{started_at: @date.to_time.change(offset: @offset, hour: 14, min: 0), stopped_at: @date.to_time.change(offset: @offset, hour: 17, min: 0)}]
        elsif (not_current_time? && @duration.nil?) # One hour duration if hour specified but no duration
          @duration = 60
        end
      end 
      working_periods_attributes unless @working_periods.present?
    end

    # @param [String] istr
    def extract_wp_from_interval(istr)
      istr.scan(/((de|à|a|entre) *\b((00|[0-9]|1[0-9]|2[0-3]) *(h|heure(s)?|:) *([0-5]?[0-9])?\b|midi|minuit) *(jusqu\')?(a|à|et) *\b((00|[0-9]|1[0-9]|2[0-3]) *(h|heure(s)?|:) *([0-5]?[0-9])?\b|midi|minuit))/).to_a.each do |interval|
        start, ending = [extract_hour(interval.first), extract_hour(interval.first)].sort # Extract two hours from interval & sort it & create working_period
        @date = @date.to_time.change(offset: @offset, hour: start.hour, min: start.min)
        @duration = ((ending - start)/60).to_i
        @working_periods.push({started_at: @date, stopped_at: @date + @duration.minutes})
      end
    end 

    # Checks if HH:MM corresponds to Time.now.HH:MM
    def not_current_time?
      now = Time.now 
      return true if (@date.change(year: now.year, month: now.month, day: now.day) - now).abs > 300
      false 
    end 

    # @param [String] type : Type of item for which we want to display all suggestions
    # @return [Json] OptJson for Ibm to display clickable buttons with every item & labels
    def optionAll type 
      pars = Procedo::Procedure.find(@procedure).parameters_of_type(type.to_sym).select{|param| Product.availables(at: @date.to_time).of_expression(param.filter).present?}
      items = pars.map{|param| [{global_label: param.human_name}, Product.availables(at: @date.to_time).of_expression(param.filter)]}.flatten # Get Label and all suggestions from parameters
      items.reject!{|prod| prod.respond_to?(:id) && self.instance_variable_get("@#{type}").any?{|reco|reco.key == prod.id}} # Remove Already chosen from suggestions
      options = items.map{|itm| (itm if itm.kind_of?(Hash))||optJsonify(itm.name, itm.id)} # Turn it to Jsonified options
      return dynamic_text(I18n.t("duke.interventions.ask.no_complement")) if options.empty?
      return dynamic_options(I18n.t("duke.interventions.ask.one_complement"), options) if options.size == 2
      return dynamic_options(I18n.t("duke.interventions.ask.what_complement_#{type}"), options)
    end 

    # @returns [Integer] newly created intervention id
    def save_intervention
      intervention_params = {procedure_name: @procedure,
                              description: "Duke : #{@description}",
                              state: 'done',
                              number: '50',
                              nature: 'record',
                              tools_attributes: tool_attributes.to_a,
                              doers_attributes: doer_attributes.to_a,
                              targets_attributes: target_attributes.to_a,
                              inputs_attributes: input_attributes.to_a,
                              working_periods_attributes: @working_periods}
      add_readings_attributes(intervention_params)
      it = Intervention.create!(intervention_params)
      return it.id
    end 

    private

    attr_accessor  :retry

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


    def extract_user_specifics(jsonD: self.to_jsonD, level: 80)
      super(jsonD: jsonD, level: level)
    end 

    # is Tenant ekyagri ?
    def ekyagri? 
      Activity.availables.none? {|act| act.family == :vine_farming}
    end 

    # does Tenant have any vegetal activity ?
    def vegetal? 
      Activity.availables.any? {|act| act.family == :plant_farming}
    end 

    # does Tenant have any animal activity ?
    def animal? 
      Activity.availables.any? {|act| act.family == :animal_farming}
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

    # @returns exclusive farming type :vine_farming || :plant_farming if exists
    def exclusive_farming_type
      farming_types = Activity.availables.select("distinct family").map(&:family)
      if (type = farming_types & %w[plant_farming vine_farming]).size.eql?(1) 
        return type.first.to_sym
      end 
    end 

    # @clean sentence
    def get_clean_sentence
      @description = @user_input.clone
      @user_input = @user_input.duke_clear
    end 

    # Create Sentence describing current intervention
    def speak_intervention
      tar_type = Procedo::Procedure.find(@procedure).parameters.find {|param| param.type == :target}
      sentence = I18n.t("duke.interventions.ask.save_intervention_#{rand(0...3)}")
      sentence += "<br>&#8226 #{I18n.t("duke.interventions.intervention")} : #{Procedo::Procedure.find(@procedure).human_name}"
      sentence += "<br>&#8226 #{I18n.t("duke.interventions.group")} : #{@crop_groups.map{|cg| cg.name}.join(", ")}" unless @crop_groups.to_a.empty?
      sentence += "<br>&#8226 #{I18n.t("duke.interventions.#{tar_type.name}")} : #{self.send(tar_type.name).map{|tar| tar.name}.join(", ")}" unless (tar_type.nil?||self.send(tar_type.name).to_a.empty?)
      sentence += "<br>&#8226 #{I18n.t("duke.interventions.tool")} : #{@tool.map{|eq| eq.name}.join(", ")}" unless @tool.to_a.empty?
      sentence += "<br>&#8226 #{I18n.t("duke.interventions.doer")} : #{@doer.map{|wk| wk.name}.join(", ")}" unless @doer.to_a.empty?
      sentence += "<br>&#8226 #{I18n.t("duke.interventions.input")} : #{@input.map{|input| "#{input.name} (#{input[:rate][:value].to_f} #{(I18n.t("duke.interventions.units.#{Procedo::Procedure.find(@procedure).parameters_of_type(:input).find {|inp| Matter.find_by_id(input.key).of_expression(inp.filter)}.handler(input[:rate][:unit]).unit.name}") if input[:rate][:unit].to_sym != :population) || Matter.find_by_id(input.key)&.unit_name} )"}.join(", ")}" unless @input.to_a.empty?
      @readings.each do |key, rd| 
        rd.to_a.each do |rd_hash| 
          sentence += "<br>&#8226 #{I18n.t("duke.interventions.readings.#{rd_hash[:indicator_name]}")} : #{(I18n.t("duke.interventions.readings.#{rd_hash.values.last}") if !number?(rd_hash.values.last))|| rd_hash.values.last}"
        end  
      end  
      sentence += "<br>&#8226 #{I18n.t("duke.interventions.date")} : #{@date.to_time.strftime("%d/%m/%Y")}"
      sentence += "<br>&#8226 #{I18n.t("duke.interventions.working_period")} : #{ @working_periods.sort_by{|wp|wp[:started_at]}.map{|wp| I18n.t("duke.interventions.working_periods", start: speak_hour(wp[:started_at]), ending:  speak_hour(wp[:stopped_at]))}.join(", ")}" 
      return sentence.gsub(/, <br>&#8226/, "<br>&#8226")
    end

    # @returns [String, Integer] Sentence to ask how much input, and input index inside @input
    def speak_input_rate
      @input.each_with_index do |input, index|
        if input[:rate][:value].nil?
          sentence = I18n.t("duke.interventions.ask.how_much_inputs_#{rand(0...2)}", input: input.name, unit: Matter.find_by_id(input.key)&.unit_name)
          return sentence, index
        end
      end
    end

    # @returns json Option understandable via IBM to display buttons
    def speak_targets
      tar_type = Procedo::Procedure.find(@procedure).parameters.find {|param| param.type == :target}.name
      candidates = self.send(tar_type).map{|tar| optJsonify(tar.name, tar.key.to_s) if tar.key? :potential}.compact
      return dynamic_options(I18n.t("duke.interventions.ask.what_targets", tar: I18n.t("duke.interventions.#{tar_type}").downcase),candidates)
    end 

    # @params [DateTime.to_s] hour
    # @returns [String] Readable hour
    def speak_hour hour 
      return hour.to_time.strftime("%-Hh%M") if hour.to_time.min.positive? 
      return hour.to_time.strftime("%-Hh")
    end 

    # Create instance_variable with tar_names 
    def tag_specific_targets
      # Creates entry for each proc-specific target type with empty array inside what's about to be parsed
      tar_from_procedure.each do |targ|
        self.instance_variable_set("@#{targ}", DukeMatchingArray.new)
      end 
    end 

    # Check if readings exits, if so, and if extract_#{reading} method exitsts, try to extract it
    def extract_intervention_readings
      @readings = Hash[*Procedo::Procedure.find(@procedure).product_parameters(true).flat_map {|param| [param.type, DukeMatchingArray.new]}]
      Procedo::Procedure.find(@procedure).product_parameters(true).map(&:readings).reject(&:empty?).flatten.each do |reading|
        begin 
          send("extract_#{reading.name}")
        rescue NoMethodError
        end 
      end 
    end

    # Extract vine_pruning_system reading
    def extract_vine_pruning_system
      pr = {"cordon_pruning" => /(royat|cordon)/, "formation_pruning" => /formation/, "gobelet_pruning" => /gobelet/, "guyot_double_pruning" => /guyot.*(doub|mult)/, "guyot_simple_pruning" => /guyot/}
      pr.each do |key, regex|
        (@readings[:target].push({indicator_name: :vine_pruning_system, indicator_datatype: :choice, choice_value: key}); break) if @user_input.matchdel(regex)
      end 
    end 

    # Extract vine stock bud charge reading
    def extract_vine_stock_bud_charge()
      if charge = @user_input.match(/(\d{1,2}) *(bourgeons|yeux|oeil)/)
        @readings[:target].push({indicator_name: :vine_stock_bud_charge, indicator_datatype: :integer, integer_value: charge[1]})
      elsif sec_charge = @user_input.match(/charge *(de|à|avec|a)? *(\d{1,2})/) 
        @readings[:target].push({indicator_name: :vine_stock_bud_charge, indicator_datatype: :integer, integer_value: sec_charge[2]})
      end 
    end 

    # Adds input rate to input DukeMatchingItem
    def add_input_rate
      @input.each_with_index do |input, index|
        if quantity = @user_input.matchdel(/(\d{1,3}(\.|,)\d{1,2}|\d{1,3}) *((g|gramme|kg|kilo|kilogramme|tonne|t|l|litre|hectolitre|hl)(s)? *(par hectare|\/ *hectare|\/ *ha)?) *(de|d\'|du)? *(la|le)? *#{input.matched}/)
          measure = get_measure(quantity[1].gsub(',','.').to_f, quantity[4], (true unless quantity[6].nil?))
        elsif sec_quantity = @user_input.matchdel(/#{input.matched} *(à|a|avec)? *(\d{1,3}(\.|,)\d{1,2}|\d{1,3}) *((gramme|g|kg|kilo|kilogramme|tonne|t|hectolitre|hl|litre|l)(s)? *(par hectare|\/ *hectare|\/ *ha)?)/)
          measure = get_measure(sec_quantity[2].gsub(',','.').to_f, sec_quantity[5], (true unless sec_quantity[7].nil?))
        else # Associate a nil population rate if we don't find a quantity
          measure = get_measure(nil.to_f, :population, nil)
        end
        if input.measure_coherent?(measure, @procedure) # Check for coherent unit
          if measure.repartition_unit.nil? #Check for repartition_unit
            measure = measure.in(Procedo::Procedure.find(@procedure).parameters_of_type(:input).find {|inp| Matter.find_by_id(input.key).of_expression(inp.filter)}.handler("net_#{measure.base_dimension}").unit.name)
            input[:rate] = {:value => measure.value.to_f, :unit => "net_#{measure.base_dimension}"}
          else 
            measure = measure.in(Procedo::Procedure.find(@procedure).parameters_of_type(:input).find {|inp| Matter.find_by_id(input.key).of_expression(inp.filter)}.handler(measure.dimension).unit.name)
            input[:rate] = {:value => measure.value.to_f, :unit => measure.dimension}
          end 
        else 
          input[:rate] = {:value => nil, :unit => :population} # Otherwise, return a nil population rate, that the user will be ask to change
        end 
      end
    end

    # @params [Integer] value 
    # @params [Unit] symbol 
    # @params [Boolean] area
    # Returns [Measure]
    def get_measure(value, unit, area)
      if unit == :population 
        return Measure.new(value, :population)
      elsif unit.match(/(kilo|kg)/)
        return Measure.new(value, "kilogram") if area.nil?
        return  Measure.new(value, "kilogram_per_hectare")
      elsif unit.match(/(gramme|g)/)
        return Measure.new(value, "gram") if area.nil?
        return  Measure.new(value, "gram_per_hectare")
      elsif unit.match(/(tonne)/) || unit == "t"
        return Measure.new(value, "ton") if area.nil?
        return  Measure.new(value, "ton_per_hectare")
      elsif unit.match(/(hectolitre|hl)/)
        return Measure.new(value, "hectoliter") if area.nil?
        return  Measure.new(value, "hectoliter_per_hectare")
      elsif unit.match(/(litre|l)/)
        return Measure.new(value, "liter") if area.nil?
        return  Measure.new(value, "liter_per_hectare")
      end
    end 

    # @return [String, String, Hash|Array|Integer] what_next, sentence, optional
    def redirect
      return ["cancel", nil, nil] if @retry == 2
      return ["ask_ambiguity", nil, @ambiguities.first] unless @ambiguities.blank?
      return ["ask_input_rate", speak_input_rate].flatten if @input.to_a.any? {|input| input[:rate][:value].nil?}
      return "save", speak_intervention, nil
    end
    
    # Redirect to user procedure selection
    # params [IBM-options] options - options to display
    def w_procedure_redirect(options)
      {
        user_input: @description,
        redirect: :what_procedure,
        optional: options
      }
    end

    # Redirect to non supported procedure msg
    def non_supported_redirect
      {
        redirect: :non_supported_proc
      }
    end

    # Redirect to cancelation msg
    def cancel_redirect
      {
        redirect: :cancel
      }
    end

    # Redirect to misunderstanding msg
    def not_understanding_redirect
      {
        redirect: :not_understanding
      }
    end

    def working_periods_attributes
      if @duration.nil? # Basic working_periods if duration.nil?:true
        @working_periods = [{started_at: @date.to_time.change(offset: @offset, hour: 8, min: 0), stopped_at: @date.to_time.change(offset: @offset, hour: 12, min: 0)},
                            {started_at: @date.to_time.change(offset: @offset, hour: 14, min: 0), stopped_at: @date.to_time.change(offset: @offset, hour: 17, min: 0)}]
      elsif @duration.kind_of?(Integer) # Specific working_periods if a duration was found
        @working_periods = [{started_at: @date.to_time.change(offset: @offset), stopped_at: @date.to_time.change(offset: @offset) + @duration.to_i.minutes}]
      end 
    end 

    # @params [hash] params : Intervention_parameters
    # Add readings to params_attributes
    def add_readings_attributes params
      @readings.delete_if{|k,v| !v.present?}.each do |key, rd|
        params["#{key}s_attributes".to_sym].each do |attr|
          attr[:readings_attributes] = rd.map{|rding| ActiveSupport::HashWithIndifferentAccess.new(rding)}
        end 
      end 
    end 

    # @return Array with target_attributes
    def target_attributes
      reference_name = Procedo::Procedure.find(@procedure).parameters.find {|param| param.type == :target}.name
      return [] if self.instance_variable_get("@#{reference_name}").blank? && @crop_groups.blank?
      if Procedo::Procedure.find(@procedure).parameters.find {|param| param.type == :target}.present?
        tar = self.instance_variable_get("@#{reference_name}").map{|tar| {reference_name: reference_name, product_id: tar.key, working_zone: Product.find_by_id(tar.key).shape}}
        cg = @crop_groups.map{|cg| CropGroup.available_crops(cg.key, "is plant or is land_parcel")}.flatten.map{|crop| {reference_name: reference_name, product_id: crop.id, working_zone: Product.find_by_id(crop.id).shape}}
        return (tar + cg).uniq{|t| t[:product_id]}
      end 
    end 

    # @return Array with input_attributes
    def input_attributes 
      return [] if @input.blank?
      if Procedo::Procedure.find(@procedure).parameters_of_type(:input).present?
        return @input.map{|input| {reference_name: input_reference_name(input.key),
                                    product_id: input.key,
                                    quantity_value: input.rate[:value].to_f,
                                    quantity_population: input.rate[:value].to_f,
                                    quantity_handler: input.rate[:unit]}}
      end
    end 

    # @return tool reference_name 
    def input_reference_name key 
      Procedo::Procedure.find(@procedure).parameters_of_type(:input).find {|inp| Matter.find_by_id(key).of_expression(inp.filter)}.name
    end 
    
    # @return Array with doer_attributes
    def doer_attributes 
      return [] if @doer.blank?
      if Procedo::Procedure.find(@procedure).parameters_of_type(:doer).present?
        return @doer.to_a.map{|wrk| {reference_name: Procedo::Procedure.find(@procedure).parameters_of_type(:doer).first.name, product_id: wrk.key}}
      end 
    end 

    # @return Array with tool_attributes
    def tool_attributes 
      return [] if @tool.blank?
      if Procedo::Procedure.find(@procedure).parameters_of_type(:tool).present?
        return @tool.to_a.map{|tool| {reference_name: tool_reference_name(tool.key), product_id: tool.key}}
      end 
    end 

    # @params [Integer] key 
    # @return tool reference_name 
    def tool_reference_name key
      reference_name = Procedo::Procedure.find(@procedure).parameters_of_type(:tool).first.name
      Procedo::Procedure.find(@procedure).parameters.find_all {|param| param.type == :tool}.each do |tool_type|
        (reference_name = tool_type.name; break;) if Equipment.of_expression(tool_type.filter).include? Equipment.find_by_id(key)
      end 
      reference_name
    end 
  
  end 
end
