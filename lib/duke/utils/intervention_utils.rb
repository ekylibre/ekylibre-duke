module Duke
  module Utils
    class InterventionUtils < Duke::Utils::DukeParsing

      def speak_intervention(parsed)
        # Create validation sentence for InterventionSkill
        # Voulez vous valider cette intervention ? : -Procedure -CropGroup - Targets -Tool -Doer -Input -Date -Duration
        sentence = I18n.t("duke.interventions.ask.save_intervention_#{rand(0...3)}")
        sentence += "<br>&#8226 #{I18n.t("duke.interventions.intervention")} : #{Procedo::Procedure.find(parsed[:procedure]).human_name}"
        unless parsed[:crop_groups].to_a.empty?
          sentence += "<br>&#8226 #{I18n.t("duke.interventions.group")} : "
          parsed[:crop_groups].each do |cg|
            sentence += "#{cg[:name]}, "
          end
        end
        # If proc has a target type and parsed[:tar] isn't empty, display targets
        unless Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :target}.nil?
          unless parsed[Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :target}.name].to_a.empty?
            sentence += "<br>&#8226 #{I18n.t("duke.interventions.#{Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :target}.name}")} : "
            parsed[Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :target}.name].each do |target|
              sentence += "#{target[:name]}, "
            end 
          end 
        end 
        unless parsed[:equipments].to_a.empty?
          sentence += "<br>&#8226 #{I18n.t("duke.interventions.tool")} : "
          parsed[:equipments].each do |eq|
            sentence += "#{eq[:name]}, "
          end
        end
        unless parsed[:workers].to_a.empty?
          sentence += "<br>&#8226 #{I18n.t("duke.interventions.worker")} : "
          parsed[:workers].each do |worker|
            sentence += "#{worker[:name]}, "
          end
        end
        unless parsed[:inputs].to_a.empty?
          sentence += "<br>&#8226 #{I18n.t("duke.interventions.input")} : "
          parsed[:inputs].each do |input|
            # For each input, if unit is population, display it, otherwise display the procedure-unit linked to the chosen handler
            sentence += "#{input[:name]} (#{input[:rate][:value].to_f} #{(I18n.t("duke.interventions.units.#{Procedo::Procedure.find(parsed[:procedure]).parameters_of_type(:input).find {|inp| Matter.find_by_id(input[:key]).of_expression(inp.filter)}.handler(input[:rate][:unit]).unit.name}") if input[:rate][:unit].to_sym != :population) || Matter.find_by_id(input[:key])&.unit_name} ), "
          end
        end
        parsed[:readings].each do |key, rd| 
          rd.to_a.each do |rd_hash| 
            sentence += "<br>&#8226 #{I18n.t("duke.interventions.readings.#{rd_hash[:indicator_name]}")} : #{(I18n.t("duke.interventions.readings.#{rd_hash.values.last}") if !is_number?(rd_hash.values.last))|| rd_hash.values.last}"
          end  
        end  
        sentence += "<br>&#8226 #{I18n.t("duke.interventions.date")} : #{parsed[:date].to_datetime.strftime("%d/%m/%Y - %H:%M")}"
        sentence += "<br>&#8226 #{I18n.t("duke.interventions.duration")} : #{speak_duration(parsed[:duration])}" 
        return sentence.gsub(/, <br>&#8226/, "<br>&#8226")
      end

      def speak_input_rate(parsed)
        # Creates "Combien de kg de bouillie bordelaise ont été utilisés ? "
        parsed[:inputs].each_with_index do |input, index|
          if input[:rate][:value].nil?
            sentence = I18n.t("duke.interventions.ask.how_much_inputs_#{rand(0...2)}", input: input[:name], unit: Matter.find_by_id(input[:key])&.unit_name)
            return sentence, index
          end
        end
      end

      def speak_targets(parsed) 
        tar_type = Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :target}.name
        candidates = parsed[tar_type].map{|tar| optJsonify(tar[:name], tar[:key].to_s) if tar.key? :potential}.compact
        return dynamic_options(I18n.t("duke.interventions.ask.what_targets", tar: I18n.t("duke.interventions.#{tar_type}").downcase),candidates)
      end 

      def speak_duration(num_in_mins)
        if num_in_mins < 60 
          return "#{num_in_mins} #{I18n.t("duke.interventions.mins")}"
        else 
          if num_in_mins.remainder(60) != 0
            return "#{num_in_mins/60}#{I18n.t("duke.interventions.hour")}#{num_in_mins.remainder(60)}"
          else 
            return "#{num_in_mins/60}#{I18n.t("duke.interventions.hour")}"
          end 
        end 
      end 

      def tag_specific_targets(parsed)
        # Creates entry for each proc-specific target type with empty array inside what's about to be parsed 
        parsed[:crop_groups] = []
        if (Procedo::Procedure.find(parsed[:procedure]).activity_families & [:vine_farming]).any?
          parsed[Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :target}.name] = []
        else
          parsed[:cultivablezones] = []
          parsed[:activity_variety] = []
        end 
      end 

      def targets_from_cz(parsed)
        tar_param = Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :target}
        unless tar_param.nil? ||parsed[:cultivablezones].to_a.empty? and parsed[:activity_variety].to_a.empty?
          tarIterator = ActivityProduction.at(parsed[:date].to_datetime)
          unless parsed[:activity_variety].to_a.empty? 
            tarIterator = ActivityProduction.at(parsed[:date].to_datetime).of_activity(Activity.select{|act| parsed[:activity_variety].map{ |var| var[:name]}.include? act.cultivation_variety_name})
          end 
          unless parsed[:cultivablezones].to_a.empty? 
            tarIterator = tarIterator.select{|act| parsed[:cultivablezones].map{ |cz| cz[:key]}.include? act.cultivable_zone_id}
          end 
          parsed[tar_param.name] = tarIterator.map {|act| act.products}
                                  .flatten
                                  .reject{|prod| !prod.available?||
                                                 (prod.is_a?(Plant) && prod.dead_at.nil? && prod.activity_production&.support.present?) and prod.activity_production.support.dead_at < parsed[:date].to_datetime||
                                                 !prod.of_expression(tar_param.filter)}
                                  .map{|tar| {key: tar.id, name: tar.name, potential: :true}}
        end 
      end

      def modification_candidates(parsed)
        # Returns to IBM an array with all the entities the user can modify given the procedure, to create buttons
        candidates = []
        candidates.push(optJsonify(I18n.t("duke.interventions.temporality")))
        [:target, :tool, :doer, :input].each do |parameter|
          unless Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == parameter}.nil?
            candidates.push(optJsonify(I18n.t("duke.interventions.#{parameter}")))
          end 
        end 
        return dynamic_options(I18n.t("duke.interventions.ask.what_modify"), candidates)
      end 

      def extract_date_and_duration(content)
        # Regrouping Date & Duration extraction, and adding a global regex that searches for both at the same time
        whole_temp = content.match(/(de|à|a) *\b(00|[0-9]|1[0-9]|2[03]) *(h|heure(s)?|:) *([0-5]?[0-9])?\b *(jusqu\')?(a|à) *\b(00|[0-9]|1[0-9]|2[03]) *(h|heure(s)?|:) *([0-5]?[0-9])?\b/)
        if whole_temp
          new_content = content.gsub(whole_temp[0], "")
          hour = extract_hour(whole_temp[0].split(/\b(a|à)/)[0])
          ending_hour = extract_hour(whole_temp[0].split(/\b(a|à)/)[2])
          day = extract_date(content)
          return DateTime.new(day.year, day.month, day.day, hour.hour, hour.min, hour.sec, "+0#{Time.now.utc_offset / 3600}:00"), ((ending_hour - hour)* 24 * 60).to_i
        end
        duration = extract_duration(content)
        date = extract_date(content)
        return date, duration
      end

      def add_input_rate(content, recognized_inputs, procedure)
        # Look for an input rate associated with each input and create a :rate entry for each input with value & unit
        recognized_inputs.each_with_index do |input, index|
          recon_input = content.split(/[\s\']/)[input[:indexes][0]..input[:indexes][-1]].join(" ")
          quantity = content.match(/(\d{1,3}(\.|,)\d{1,2}|\d{1,3}) *((g|gramme|kg|kilo|kilogramme|tonne|t|l|litre|hectolitre|hl)(s)? *(par hectare|\/ *hectare|\/ *ha)?) *(de|d\'|du)? *(la|le)? *#{recon_input}/)
          sec_quantity = content.match(/#{recon_input} *(à|a|avec)? *(\d{1,3}(\.|,)\d{1,2}|\d{1,3}) *((gramme|g|kg|kilo|kilogramme|tonne|t|hectolitre|hl|litre|l)(s)? *(par hectare|\/ *hectare|\/ *ha)?)/)
          # If we find a quantity, we parse it, otherwise we associate a "nil population"
          if quantity
            unit = quantity[4]
            rate = quantity[1].gsub(',','.')
            area = (true unless quantity[6].nil?)
          elsif sec_quantity
            unit = sec_quantity[5]
            rate = sec_quantity[2].gsub(',','.')
            area = (true unless sec_quantity[7].nil?)
          else
            unit = :population
            rate = nil
            area = nil
          end
          # We create a measure from what just got parsed
          measure = get_measure(rate.to_f, unit, area)
          # If measure in mass or volume , and procedure can handle this type of indicators for its inputs and net dimension exists for specific input
          if [:mass, :volume].include? measure.base_dimension.to_sym and !Procedo::Procedure.find(procedure).parameters_of_type(:input).find {|inp| Matter.find_by_id(input[:key]).of_expression(inp.filter)}.handler("net_#{measure.base_dimension}").nil? and !Matter.find_by_id(input[:key])&.send("net_#{measure.base_dimension}").zero?
            # Check if distance has repartion unit & convert value in correct proc unit & modify rate entry in the input hash 
            if measure.repartition_unit.nil?
              measure = measure.in(Procedo::Procedure.find(procedure).parameters_of_type(:input).find {|inp| Matter.find_by_id(input[:key]).of_expression(inp.filter)}.handler("net_#{measure.base_dimension}").unit.name)
              input[:rate] = {:value => measure.value.to_f, :unit => "net_#{measure.base_dimension}"}
            else 
              measure = measure.in(Procedo::Procedure.find(procedure).parameters_of_type(:input).find {|inp| Matter.find_by_id(input[:key]).of_expression(inp.filter)}.handler(measure.dimension).unit.name)
              input[:rate] = {:value => measure.value.to_f, :unit => measure.dimension}
            end 
          else 
            # Otherwise, return a nil population rate, that the user will be ask to change
            input[:rate] = {:value => nil, :unit => :population}
          end 
        end
        return recognized_inputs
      end

      def get_measure(value, unit, area)
        # Returns a measure from what's parsed in the add_input_rate 
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
      
      def ok_procedure?(procedure) 
        return [false, procedure] if procedure.nil?
        return [true, procedure] if Procedo::Procedure.find(procedure).present? && (Procedo::Procedure.find(procedure).activity_families & [:vine_farming, :plant_farming]).any?
        return [true, procedure.split(/[|]/).first] if procedure.scan(/[|]/).present? && !Activity.availables.any? {|act| act[:family] != :vine_farming}
        [false, procedure]
      end 

      def guide_to_procedure(procedure, content) 
        if procedure.nil?
          return (suggest_categories_from_fam(exclusive_farming_type, content) if exclusive_farming_type.present?) ||asking_intervention_family(content)
        elsif procedure.scan(/[&]/).present? 
          return (suggest_categories_from_amb(procedure, content) if procedure.split(/[&]/).size > 1) ||suggest_proc_from_category(procedure.split(/[&]/).first, content)
        end 
        return suggest_categories_from_fam(procedure.to_sym, content) if [:plant_farming, :vine_farming].include? procedure.to_sym 
        return suggest_viti_vegetal_proc(procedure, content) if procedure.scan(/[|]/).present?
        return suggest_procedure_disambiguation(procedure, content) if procedure.scan(/[~]/).present?
        return {redirect: :get_help, sentence: I18n.t("duke.interventions.help.example")} if procedure.match(/get_help/)
        return {redirect: :non_supported_proc} if Procedo::Procedure.find(procedure).present? && (Procedo::Procedure.find(procedure).activity_families & [:vine_farming, :plant_farming]).empty?
        return {redirect: :cancel} if procedure.scan(/cancel/).present?
        return {redirect: :not_understanding}
      end 

      def asking_intervention_family(content)
        families = [:plant_farming, :vine_farming].map{|fam| optJsonify(Onoma::ActivityFamily[fam].human_name, fam) }
        families.push(optJsonify(I18n.t("duke.interventions.cancel"), :cancel))
        return {parsed: {user_input: content}, redirect: :what_procedure, optional: dynamic_options(I18n.t("duke.interventions.ask.what_family"), families)}
      end 

      def suggest_categories_from_fam(family, content) 
        categories = Onoma::ProcedureCategory.select { |c| c.activity_family.include?(family.to_sym) and !Procedo::Procedure.of_main_category(c).empty? }.map{|cat|optJsonify(cat.human_name, "#{cat.name}&")}
        categories.push(optJsonify(I18n.t("duke.interventions.help.get_help"), :get_help))
        return {parsed: {user_input: content}, redirect: :what_procedure, optional: dynamic_options(I18n.t("duke.interventions.ask.what_category"), categories)}
      end 

      def suggest_categories_from_amb(procedure, content)
        categories = procedure.split(/[&]/).map{|c| optJsonify(Onoma::ProcedureCategory.find(c).human_name, "#{c}&")}
        return {parsed: {user_input: content}, redirect: :what_procedure, optional: dynamic_options(I18n.t("duke.interventions.ask.what_category"), categories)}
      end 

      def suggest_proc_from_category(cat, content)
        procs = Procedo::Procedure.of_main_category(cat).sort_by(&:position).map {|proc| optJsonify(proc.human_name, proc.name)}
        return {parsed: {user_input: content}, redirect: :what_procedure, optional: dynamic_options(I18n.t("duke.interventions.ask.which_procedure"), procs)}
      end 

      def suggest_viti_vegetal_proc(procedure, content)
        procs = procedure.split(/[|]/).map{|p_name| Procedo::Procedure.find(p_name) }.map{|proc|optJsonify("#{proc.human_name} - #{I18n.t("duke.interventions.#{proc.of_activity_family?(:vine_farming)}_vine_production")} ", proc.name)}
        return {parsed: {user_input: content}, redirect: :what_procedure, optional: dynamic_options(I18n.t("duke.interventions.ask.which_procedure"), procs)}
      end 

      def suggest_procedure_disambiguation(procedure, content)
        procs = procedure.split(/[~]/).map{|p_name| optJsonify(Procedo::Procedure.find(p_name).human_name, p_name)}
        return {parsed: {user_input: content}, redirect: :what_procedure, optional: dynamic_options(I18n.t("duke.interventions.ask.which_procedure"), procs)}
      end 

      def exclusive_farming_type() 
        farming_types = Activity.availables.map{|act| act[:family] if [:vine_farming, :plant_farming].include? act[:family].to_sym}.compact.uniq
        if farming_types.size == 1 
          return farming_types.first 
        end 
        nil
      end 

      def redirect(parsed)
        # Decide where to redirect the user
        if parsed[:retry] == 2
          # If user fails twice to specify a value, we cancel
          return "cancel", nil, nil
        end
        unless parsed[:ambiguities].to_a.empty?
          # If there's an ambiguity, we solve it
          return "ask_ambiguity", nil, parsed[:ambiguities][0]
        end
        unless parsed[Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :target}.name].nil?
          if parsed[Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :target}.name].map{|tar| tar.key? :potential}.count(true) > 1
            return "ask_which_targets", nil , speak_targets(parsed)
          end 
        end 
        if parsed[:inputs].to_a.any? {|input| input[:rate][:value].nil?}
          # If there's an input without rate, we ask the user its rate
          sentence, optional = speak_input_rate(parsed)
          return "ask_input_rate", sentence, optional
        end
        # Otherwise we can potentially save the intervention
        return "save", speak_intervention(parsed), nil
      end

      def extract_intervention_readings(user_input, parsed)
        # Given Procedure Type, check if readings exits, if so, and if extract_#{reading} method exitsts, try to extract it
        parsed[:readings] = Hash[*Procedo::Procedure.find(parsed[:procedure]).product_parameters(true).flat_map {|param| [param.type, []]}]
        Procedo::Procedure.find(parsed[:procedure]).product_parameters(true).map(&:readings).reject(&:empty?).flatten.each do |reading|
          begin 
            send("extract_#{reading.name}", user_input, parsed)
          rescue NoMethodError
          end 
        end 
      end

      def extract_vine_pruning_system(content, parsed)
        # Extract vine pruning system, for pruning procedures
        pr = {"cordon_pruning" => /(royat|cordon)/, "formation_pruning" => /formation/, "gobelet_pruning" => /gobelet/, "guyot_double_pruning" => /guyot.*(doub|mult)/, "guyot_simple_pruning" => /guyot/}
        pr.each do |key, regex|
          if content.match(regex)
            parsed[:readings][:target].push({indicator_name: :vine_pruning_system, indicator_datatype: :choice, choice_value: key})
            break
          end 
        end 
      end 

      def extract_vine_stock_bud_charge(content, parsed)
        # Extract vine stock bud charge, for pruning procedures
        charge = content.match(/(\d{1,2}) *(bourgeons|yeux|oeil)/)
        sec_charge = content.match(/charge *(de|à|avec|a)? *(\d{1,2})/)
        if charge
          parsed[:readings][:target].push({indicator_name: :vine_stock_bud_charge, indicator_datatype: :integer, integer_value: charge[1]})
        elsif sec_charge 
          parsed[:readings][:target].push({indicator_name: :vine_stock_bud_charge, indicator_datatype: :integer, integer_value: sec_charge[2]})
        end 
      end 
    
    end 
  end
end
