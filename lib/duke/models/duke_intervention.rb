module Duke
  module Models
    class DukeIntervention < Duke::Models::DukeArticle
      
      attr_accessor :procedure, :inputs, :workers, :equipments, :retry, :plant, :cultivation, :crop_groups, :land_parcel, :cultivablezones, :activity_variety, :ambiguities
      attr_reader :specific

      def initialize(**args)
        super()
        @procedure = nil
        @inputs, @workers, @equipments, @crop_group = Array.new(4, Duke::Models::DukeMatchingArray.new)
        @retry = 0
        @ambiguities = []
        args.each{|k, v| instance_variable_set("@#{k}", v)}
        @description = @user_input.clone
        @matchArrs = [:inputs, :workers, :equipments, :crop_group, :plant, :cultivation, :crop_groups, :land_parcel, :cultivablezones, :activity_variety]
      end 

      # @creates intervention from json
      # @returns DukeIntervention
      def recover_from_hash(jsonD) 
        jsonD.slice(*@matchArrs).each{|k,v| self.instance_variable_set("@#{k}", Duke::Models::DukeMatchingArray.new(arr: v))}
        jsonD.except(*@matchArrs).each{|k,v| self.instance_variable_set("@#{k}", v)}
        self
      end 

      # @returns DukeIntervention to_json with given parameters
      def to_jsonD(*args) 
        return ActiveSupport::HashWithIndifferentAccess.new(self.as_json) if args.empty?
        return ActiveSupport::HashWithIndifferentAccess.new(Hash[args.flatten.map{|arg| [arg, self.send(arg)] if self.respond_to? arg}.compact])
      end 

      # @returns json Option with all clickable buttons understandable by IBM
      def modification_candidates
        candidates = [optJsonify(I18n.t("duke.interventions.temporality"))]
        [:target, :tool, :doer, :input].each do |parameter|
          unless Procedo::Procedure.find(@procedure).parameters.find {|param| param.type == parameter}.nil?
            candidates.push(optJsonify(I18n.t("duke.interventions.#{parameter}")))
          end 
        end 
        return dynamic_options(I18n.t("duke.interventions.ask.what_modify"), candidates)
      end 

      # @returns bln, is procedure_parseable?
      def ok_procedure? 
        return false if @procedure.blank?
        return true if Procedo::Procedure.find(@procedure).present? && (Procedo::Procedure.find(@procedure).activity_families & [:vine_farming, :plant_farming]).any?
        if @procedure.scan(/[|]/).present? && !Activity.availables.any? {|act| act[:family] != :vine_farming}
          @procedure = @procedure.split(/[|]/).first
          return true
        end 
        false
      end 
      
      # @return json with next_step if procedure is not parseable
      def guide_to_procedure
        if @procedure.blank? # Suggest categories if family.uniq, family
          return (suggest_categories_from_fam(exclusive_farming_type) if exclusive_farming_type.present?) ||asking_intervention_family
        elsif @procedure.scan(/[&]/).present? # (One or multiple category(ies) matched
          if @procedure.split(/[&]/).size == 1 
            @procedure = @procedure.split(/[&]/).first 
            return suggest_proc_from_category
          else 
            return suggest_categories_from_amb
          end 
        end 
        return suggest_categories_from_fam if [:plant_farming, :vine_farming].include? @procedure.to_sym # Received a family
        return suggest_viti_vegetal_proc if @procedure.scan(/[|]/).present? # Ambiguity between vegetal & viti proc
        return suggest_procedure_disambiguation if @procedure.scan(/[~]/).present?
        return {redirect: :get_help, sentence: I18n.t("duke.interventions.help.example")} if @procedure.match(/get_help/)
        return {redirect: :non_supported_proc} if Procedo::Procedure.find(@procedure).present? && (Procedo::Procedure.find(@procedure).activity_families & [:vine_farming, :plant_farming]).empty?
        return {redirect: :cancel} if @procedure.scan(/cancel/).present?
        return {redirect: :not_understanding}
      end 

      # @params [String] proc_word: literal word that matched a procedure
      def parse_sentence(proc_word: nil)
        parse_temporality(proc_word: proc_word)  # getting cleaned user_input and finding when it happened and how long it lasted
        return if @user_input.blank? # Return if user_input is now empty
        tag_specific_targets  # Tag the specific types of targets for this intervention
        extract_user_specifics  # Then extract every possible user_specifics elements form the sentence (here : inputs, workers, equipments, targets)  
        add_input_rate  # Look for a specified rate for the input, or attribute nil
        extract_intervention_readings  # extract_readings 
        find_ambiguity # Loof for ambiguities in what has been parsed
        targets_from_cz # Try and create targets from cultivableZones and Varieties (for :plant_farming) 
      end 
      
      # @param [String] sp : specific item type 
      def parse_specific(sp)
        get_clean_sentence
        @specific = (tag_specific_targets if sp.to_sym.eql? :targets)||sp
        extract_user_specifics(jsonD: self.to_jsonD(@specific, :procedure, :date, :user_input), level: 0.79)
        add_input_rate if sp.to_sym == :inputs 
        find_ambiguity
      end 

      # @params [String] proc_word: literal word that matched a procedure
      def parse_temporality(proc_word: nil)
        get_clean_sentence(proc_word: proc_word)
        extract_date_and_duration
      end 

      # @params: [DukeIntervention] int : previous DukeIntervention 
      # @params: [String] sp 
      def join_specific(int:, sp:)
        full_jsonD = self.to_jsonD.merge(int.to_jsonD(int.specific, :ambiguities))
        self.recover_from_hash(full_jsonD)
        targets_from_cz if int.specific != sp && Procedo::Procedure.find(@procedure).activity_families.include?(:plant_farming)
        self.update_description(int.description)
      end 

      # @params : [DukeIntervention] int : previous DukeIntervention
      def join_temporality(int)
        choose_date(int.date)
        choose_duration(int.duration)
        self.update_description(int.description)
      end 

      # @params : [Integer] value : Integer parsed by ibm
      def extract_number_parameter(value)
        val = super(value) 
        @retry += 1 if val.nil? 
        val 
      end 

      # @set new instance variables with clicked targets
      def parse_multiple_targets 
        tar_type = Procedo::Procedure.find(@procedure).parameters.find {|param| param.type == :target}.name
        if @user_input.match(/^(\d{1,5}(\|{3}|\b))*$/) # If response type matches a multiple click response
          every_choices = @user_input.split(/[|]/).map{|num| num.to_i}  # Creating a list with all integers corresponding to targets.ids chosen by the user
          new_tars = self.instance_variable_get("@#{tar_type}").map{|tar| tar.except!(:potential) if every_choices.include? tar.key }.compact  # if the key is in every_choices, we keep it
        else 
          new_tars = Duke::Models::DukeMatchingArray.new
        end 
        self.instance_variable_set("@#{tar_type}", new_tars)
      end 

      # @returns [Integer] newly created intervention id
      def save_intervention
        byebug
        intervention_params = {procedure_name: @procedure,
                               description: "Duke : #{@description}",
                               state: 'done',
                               number: '50',
                               nature: 'record',
                               tools_attributes: tool_attributes.to_a,
                               doers_attributes: doer_attributes.to_a,
                               targets_attributes: target_attributes.to_a,
                               inputs_attributes: input_attributes.to_a,
                               working_periods_attributes: working_periods_attributes.to_a}
        add_readings_attributes(intervention_params)
        it = Intervention.create!(intervention_params)
        return it.id
      end 

      private

      # @returns json
      def asking_intervention_family
        families = [:plant_farming, :vine_farming].map{|fam| optJsonify(Onoma::ActivityFamily[fam].human_name, fam) }
        families.push(optJsonify(I18n.t("duke.interventions.cancel"), :cancel))
        return {parsed: {user_input: @user_input}, redirect: :what_procedure, optional: dynamic_options(I18n.t("duke.interventions.ask.what_family"), families)}
      end 

      # @returns json
      def suggest_categories_from_fam(family) 
        categories = Onoma::ProcedureCategory.select { |c| c.activity_family.include?(family.to_sym) and !Procedo::Procedure.of_main_category(c).empty? }.map{|cat|optJsonify(cat.human_name, "#{cat.name}&")}
        categories.push(optJsonify(I18n.t("duke.interventions.help.get_help"), :get_help))
        return {parsed: {user_input: @user_input}, redirect: :what_procedure, optional: dynamic_options(I18n.t("duke.interventions.ask.what_category"), categories)}
      end 

      # @returns json
      def suggest_categories_from_amb()
        categories = @procedure.split(/[&]/).map{|c| optJsonify(Onoma::ProcedureCategory.find(c).human_name, "#{c}&")}
        return {parsed: {user_input: @user_input}, redirect: :what_procedure, optional: dynamic_options(I18n.t("duke.interventions.ask.what_category"), categories)}
      end 

      # @returns json
      def suggest_proc_from_category()
        procs = Procedo::Procedure.of_main_category(@procedure).sort_by(&:position).map {|proc| optJsonify(proc.human_name, proc.name)}
        return {parsed: {user_input: @user_input}, redirect: :what_procedure, optional: dynamic_options(I18n.t("duke.interventions.ask.which_procedure"), procs)}
      end 

      # @returns json
      def suggest_viti_vegetal_proc()
        procs = @procedure.split(/[|]/).map{|p_name| Procedo::Procedure.find(p_name) }.map{|proc|optJsonify("#{proc.human_name} - #{I18n.t("duke.interventions.#{proc.of_activity_family?(:vine_farming)}_vine_production")} ", proc.name)}
        return {parsed: {user_input: @user_input}, redirect: :what_procedure, optional: dynamic_options(I18n.t("duke.interventions.ask.which_procedure"), procs)}
      end 

      # @returns json
      def suggest_procedure_disambiguation()
        procs = @procedure.split(/[~]/).map{|p_name| optJsonify(Procedo::Procedure.find(p_name).human_name, p_name)}
        return {parsed: {user_input: @user_input}, redirect: :what_procedure, optional: dynamic_options(I18n.t("duke.interventions.ask.which_procedure"), procs)}
      end 

      # @returns exclusive farming type :vine_farming || :plant_farming if exists
      def exclusive_farming_type() 
        farming_types = Activity.availables.map{|act| act[:family] if [:vine_farming, :plant_farming].include? act[:family].to_sym}.compact.uniq
        if farming_types.size == 1 
          return farming_types.first 
        end 
        nil
      end 

      # @clean sentence
      def get_clean_sentence(proc_word: nil)
        @description = @user_input.clone
        unless proc_word.nil?
          @user_input = @user_input.gsub(proc_word, "")
        end 
        @user_input = clear_string
      end 

      # Create Sentence describing current intervention
      def speak_intervention
        tar_type = Procedo::Procedure.find(@procedure).parameters.find {|param| param.type == :target}
        sentence = I18n.t("duke.interventions.ask.save_intervention_#{rand(0...3)}")
        sentence += "<br>&#8226 #{I18n.t("duke.interventions.intervention")} : #{Procedo::Procedure.find(@procedure).human_name}"
        sentence += "<br>&#8226 #{I18n.t("duke.interventions.group")} : #{@crop_groups.map{|cg| cg.name}.join(", ")}" unless @crop_groups.to_a.empty?
        sentence += "<br>&#8226 #{I18n.t("duke.interventions.#{tar_type.name}")} : #{self.send(tar_type.name).map{|tar| tar.name}.join(", ")}" unless (tar_type.nil?||self.send(tar_type.name).to_a.empty?)
        sentence += "<br>&#8226 #{I18n.t("duke.interventions.tool")} : #{@equipments.map{|eq| eq.name}.join(", ")}" unless @equipments.to_a.empty?
        sentence += "<br>&#8226 #{I18n.t("duke.interventions.worker")} : #{@workers.map{|wk| wk.name}.join(", ")}" unless @workers.to_a.empty?
        sentence += "<br>&#8226 #{I18n.t("duke.interventions.input")} : #{@inputs.map{|input| "#{input.name} (#{input[:rate][:value].to_f} #{(I18n.t("duke.interventions.units.#{Procedo::Procedure.find(@procedure).parameters_of_type(:input).find {|inp| Matter.find_by_id(input.key).of_expression(inp.filter)}.handler(input[:rate][:unit]).unit.name}") if input[:rate][:unit].to_sym != :population) || Matter.find_by_id(input.key)&.unit_name} )"}.join(", ")}" unless @inputs.to_a.empty?
        @readings.each do |key, rd| 
          rd.to_a.each do |rd_hash| 
            sentence += "<br>&#8226 #{I18n.t("duke.interventions.readings.#{rd_hash[:indicator_name]}")} : #{(I18n.t("duke.interventions.readings.#{rd_hash.values.last}") if !is_number?(rd_hash.values.last))|| rd_hash.values.last}"
          end  
        end  
        sentence += "<br>&#8226 #{I18n.t("duke.interventions.date")} : #{@date.to_time.strftime("%d/%m/%Y")}"
        sentence += "<br>&#8226 #{I18n.t("duke.interventions.working_period")} : #{speak_working_periods}" 
        return sentence.gsub(/, <br>&#8226/, "<br>&#8226")
      end

      def speak_working_periods 
        if @duration.kind_of? Array 
          return @duration.map{|start, ending| I18n.t("duke.interventions.working_periods", start: "#{start}h", ending: "#{ending}h")}.join(", ")
        else
          ending_date = (@date.to_time + @duration.to_i.minutes).to_time.strftime("%H:%M")
          return I18n.t("duke.interventions.working_periods", start: @date.to_time.strftime("%H:%M"), ending: ending_date)
        end 
      end  

      # @returns [String, Integer] Sentence to ask how much input, and input index inside @inputs
      def speak_input_rate
        @inputs.each_with_index do |input, index|
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
      
      # Create instance_variable with tar_names 
      def tag_specific_targets
        # Creates entry for each proc-specific target type with empty array inside what's about to be parsed
        tar_from_procedure.each do |targ|
          self.instance_variable_set("@#{targ}", Duke::Models::DukeMatchingArray.new)
        end 
      end 

      # Extract targets from cultivable_zone and cultivation variety for vegetal_procedures
      def targets_from_cz
        tar_param = Procedo::Procedure.find(@procedure).parameters.find {|param| param.type == :target}
        unless tar_param.nil? ||@cultivablezones.to_a.empty? and @activity_variety.to_a.empty?
          tarIterator = ActivityProduction.at(@date.to_time)
          unless @activity_variety.to_a.empty? 
            tarIterator = ActivityProduction.at(@date.to_time).of_activity(Activity.select{|act| @activity_variety.map{ |var| var.name}.include? act.cultivation_variety_name})
          end 
          unless @cultivablezones.to_a.empty? 
            tarIterator = tarIterator.select{|act| @cultivablezones.map{ |cz| cz.key}.include? act.cultivable_zone_id}
          end 
          self.instance_variable_set("@#{tar_param.name}", tarIterator.map {|act| act.products}
                                                                      .flatten
                                                                      .reject{|prod| !prod.available?||
                                                                              (prod.is_a?(Plant) && prod.dead_at.nil? && prod.activity_production&.support.present?) and prod.activity_production.support.dead_at < @date.to_time||
                                                                              !prod.of_expression(tar_param.filter)}
                                                                      .map{|tar| {key: tar.id, name: tar.name, potential: :true}})
        end 
      end

      # Check if readings exits, if so, and if extract_#{reading} method exitsts, try to extract it
      def extract_intervention_readings
        @readings = Hash[*Procedo::Procedure.find(@procedure).product_parameters(true).flat_map {|param| [param.type, Duke::Models::DukeMatchingArray.new]}]
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

      # Extract both date_and duration
      def extract_date_and_duration
        input_clone = @user_input.clone 
        whole_temp = @user_input.matchdel(/(de|à|a) *\b(00|[0-9]|1[0-9]|2[03]) *(h|heure(s)?|:) *([0-5]?[0-9])?\b *(jusqu\')?(a|à) *\b(00|[0-9]|1[0-9]|2[03]) *(h|heure(s)?|:) *([0-5]?[0-9])?\b/)
        extract_duration
        extract_date
        if input_clone.match("matin") 
          @duration = [[8, 12]]
        elsif input_clone.match("(apr(e|è)?s( |-)?midi|apr(e|è)m|apm)")
          @duration = [[14, 17]]
        elsif input_clone.match("journ(é|e)e")
          @duration = [[8, 12], [14, 17]]
        elsif whole_temp
          starting_hour = extract_hour(whole_temp[0].split(/\b(a|à)/)[0])
          @date = @date.change(hour: starting_hour.hour, min: starting_hour.min)
          @duration =  ((extract_hour(whole_temp[0].split(/\b(a|à)/)[2]) - starting_hour)* 24 * 60).to_i
        elsif not_current_time?
          @duration = 60
        end
      end

      # Checks if HH:MM corresponds to Time.now.HH:MM
      def not_current_time?
        now = Time.now 
        return true if (@date.change(year: now.year, month: now.month, day: now.day) - now).abs > 300
        false 
      end 

      # Adds input rate to input DukeMatchingItem
      def add_input_rate
        @inputs.each_with_index do |input, index|
          if quantity = @user_input.matchdel(/(\d{1,3}(\.|,)\d{1,2}|\d{1,3}) *((g|gramme|kg|kilo|kilogramme|tonne|t|l|litre|hectolitre|hl)(s)? *(par hectare|\/ *hectare|\/ *ha)?) *(de|d\'|du)? *(la|le)? *#{input.matched}/)
            measure = get_measure(quantity[1].gsub(',','.').to_f, quantity[4], (true unless quantity[6].nil?))
          elsif sec_quantity = @user_input.matchdel(/#{input.matched} *(à|a|avec)? *(\d{1,3}(\.|,)\d{1,2}|\d{1,3}) *((gramme|g|kg|kilo|kilogramme|tonne|t|hectolitre|hl|litre|l)(s)? *(par hectare|\/ *hectare|\/ *ha)?)/)
            measure = get_measure(sec_quantity[2].gsub(',','.').to_f, sec_quantity[5], (true unless sec_quantity[7].nil?))
          else # Associate a nil population rate if we don't find a quantity
            measure = get_measure(nil.to_f, :population, nil)
          end
          if input.has_coherent_measure(measure, @procedure) # Check for coherent unit
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

      # @return [String, String, ?] what_next, sentence, optional
      def redirect
        return ["cancel", nil, nil] if @retry == 2
        return ["ask_ambiguity", nil, @ambiguities.first] unless @ambiguities.blank?
        param_type = Procedo::Procedure.find(@procedure).parameters.find {|param| param.type == :target}.name
        return ["ask_which_targets", nil , speak_targets] if self.send(param_type).present? && self.send(param_type).map{|tar| tar.key? :potential}.count(true) > 1
        return ["ask_input_rate", speak_input_rate].flatten if @inputs.to_a.any? {|input| input[:rate][:value].nil?}
        return "save", speak_intervention, nil
      end

      def working_periods_attributes
        offset = "+0#{Time.at(@date.to_time).utc_offset / 3600}:00"
        if @duration.kind_of? Array 
          return @duration.map{|start, ending| { started_at: @date.to_time.change(hour: start, min: 0, offset: offset) , stopped_at: @date.to_time.change(hour: ending, min: 0, offset: offset)}}
        else  
          return [{started_at: @date.to_time.change(offset: offset), stopped_at: @date.to_time.change(offset: offset) + @duration.to_i.minutes}]
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
        if Procedo::Procedure.find(@procedure).parameters.find {|param| param.type == :target}.present?
          tar = self.instance_variable_get("@#{reference_name}").map{|tar| {reference_name: reference_name, product_id: tar.key, working_zone: Product.find_by_id(tar.key).shape}}
          cg = @crop_groups.map{|cg| CropGroup.available_crops(cg.key, "is plant or is land_parcel")}.flatten.map{|crop| {reference_name: reference_name, product_id: crop.id, working_zone: Product.find_by_id(crop.id).shape}}
          return (tar + cg).uniq{|t| t[:product_id]}
        end 
      end 

      # @return Array with input_attributes
      def input_attributes 
        if Procedo::Procedure.find(@procedure).parameters_of_type(:input).present?
          return @inputs.map{|input| {reference_name: input_reference_name(input.key),
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
        if Procedo::Procedure.find(@procedure).parameters_of_type(:doer).present?
          return @workers.to_a.map{|wrk| {reference_name: Procedo::Procedure.find(@procedure).parameters_of_type(:doer).first.name, product_id: wrk.key}}
        end 
      end 

      # @return Array with tool_attributes
      def tool_attributes 
        if Procedo::Procedure.find(@procedure).parameters_of_type(:tool).present?
          return @equipments.to_a.map{|tool| {reference_name: tool_reference_name(tool.key), product_id: tool.key}}
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
end
