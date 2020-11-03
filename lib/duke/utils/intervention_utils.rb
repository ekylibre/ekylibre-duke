module Duke
  module Utils
    class InterventionUtils < Duke::Utils::DukeParsing

      def speak_intervention(params)
        # Create validation sentence for InterventionSkill
        I18n.locale = :fra
        sentence = I18n.t("duke.interventions.ask.save_intervention_#{rand(0...3)}")
        sentence += "<br>&#8226 #{I18n.t("duke.interventions.intervention")} : #{Procedo::Procedure.find(params[:procedure]).human_name}"
        unless params[:crop_groups].to_a.empty?
          sentence += "<br>&#8226 #{I18n.t("duke.interventions.group")} : "
          params[:crop_groups].each do |cg|
            sentence += "#{cg[:name]}, "
          end
        end
        unless Procedo::Procedure.find(params[:procedure]).parameters.find {|param| param.type == :target}.nil?
          unless params[Procedo::Procedure.find(params[:procedure]).parameters.find {|param| param.type == :target}.name].to_a.empty?
            sentence += "<br>&#8226 #{I18n.t("duke.interventions.#{Procedo::Procedure.find(params[:procedure]).parameters.find {|param| param.type == :target}.name}")} : "
            params[Procedo::Procedure.find(params[:procedure]).parameters.find {|param| param.type == :target}.name].each do |target|
              sentence += "#{target[:name]}, "
            end 
          end 
        end 
        unless params[:equipments].to_a.empty?
          sentence += "<br>&#8226 #{I18n.t("duke.interventions.tool")} : "
          params[:equipments].each do |eq|
            sentence += "#{eq[:name]}, "
          end
        end
        unless params[:workers].to_a.empty?
          sentence += "<br>&#8226 #{I18n.t("duke.interventions.worker")} : "
          params[:workers].each do |worker|
            sentence += "#{worker[:name]}, "
          end
        end
        unless params[:inputs].to_a.empty?
          sentence += "<br>&#8226 #{I18n.t("duke.interventions.input")} : "
          params[:inputs].each do |input|
            sentence += "#{input[:name]} (#{input[:rate][:value].to_f} #{(I18n.t("nomenclatures.units.items.#{Procedo::Procedure.find(params[:procedure]).parameters_of_type(:input).find {|inp| Matter.where("id = #{input[:key]}").first.of_expression(inp.filter)}.handler(input[:rate][:unit]).unit.name}") if input[:rate][:unit].to_sym != :population) || Matter.where("id = #{input[:key]}").first&.unit_name}), "
          end
        end
        sentence += "<br>&#8226 #{I18n.t("duke.interventions.date")} : #{params[:date].to_datetime.strftime("%d/%m/%Y - %H:%M")}"
        sentence += "<br>&#8226 #{I18n.t("duke.interventions.duration")} : #{params[:duration]} #{I18n.t("duke.interventions.mins")}"
        return sentence.gsub(/, <br>&#8226/, "<br>&#8226")
      end

      def speak_input_rate(params)
        # Creates "Combien de kg de bouillie bordelaise ont été utilisés ? "
        # Return the sentence, and the index of the destination inside params[:destination] to transfer as an optional value to IBM 
        I18n.locale = :fra
        params[:inputs].each_with_index do |input, index|
          if input[:rate][:value].nil?
            sentence = I18n.t("duke.interventions.ask.how_much_inputs_#{rand(0...2)}", input: input[:name], unit: (Procedo::Procedure.find(params[:procedure]).parameters_of_type(:input).find {|inp| Matter.where("id = #{input[:key]}").first.of_expression(inp.filter)}.handler(input[:rate][:unit]).unit.name if input[:rate][:unit].to_sym != :population) || Matter.where("id = #{input[:key]}").first&.unit_name)
            return sentence, index
          end
        end
      end

      def disambiguate_procedure(procs, delimiter)
        I18n.locale = :fra
        optional = []
        if delimiter == "|"
          family = :viti
          procs.split(/[|]/).each do |proc| 
            family = :vegetal if Procedo::Procedure.find(proc).activity_families.include? :plant_farming
            optional.push({:key => proc, :human => "#{Procedo::Procedure.find(proc).human_name} - #{I18n.t("duke.interventions.#{family}_production")}"})
          end 
          return :ask_proc, I18n.t("duke.interventions.ask.which_procedure"), optional
        else 
          procs.split(/[~]/).each do |proc|
            optional.push({:key => proc, :human => "#{Procedo::Procedure.find(proc).human_name}"})
          end 
          return :ask_proc, I18n.t("duke.interventions.ask.which_procedure"), optional
        end 
      end 

      def tag_specific_targets(parsed)
        unless Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :target}.nil?
          parsed[:crop_groups] = []
          parsed[Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :target}.name] = []
        end 
      end 

      def modification_candidates(parsed)
        I18n.locale = :fra
        candidates = [I18n.t("duke.interventions.temporality")]
        unless Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :target}.nil?
          candidates.push(I18n.t("duke.interventions.cultivation"))
        end 
        unless Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :tool}.nil?
          candidates.push(I18n.t("duke.interventions.tool"))
        end 
        unless Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :doer}.nil?
          candidates.push(I18n.t("duke.interventions.worker"))
        end 
        unless Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :input}.nil?
          candidates.push(I18n.t("duke.interventions.input"))
        end 
        return candidates
      end 

      def extract_date_and_duration(content)
        whole_temp = content.match(/(de|à|a) *\b(00|[0-9]|1[0-9]|2[03]) *(h|heure(s)?|:) *([0-5]?[0-9])?\b *(jusqu\')?(a|à) *\b(00|[0-9]|1[0-9]|2[03]) *(h|heure(s)?|:) *([0-5]?[0-9])?\b/)
        if whole_temp
          new_content = content.gsub(whole_temp[0], "")
          hour, _c = extract_hour(whole_temp[0].split(/\b(a|à)/)[0])
          ending_hour, _c = extract_hour(whole_temp[0].split(/\b(a|à)/)[2])
          day, _c = extract_date(content)
          return DateTime.new(day.year, day.month, day.day, hour.hour, hour.min, hour.sec), ((ending_hour - hour)* 24 * 60).to_i, new_content
        end
        duration, content = extract_duration(content)
        date, content = extract_date(content)
        return date, duration, content
      end

      def add_input_rate(content, recognized_inputs, procedure)
        # This function adds a 1 population quantity to every input that has been found
        # Next step could be to match this type of regex : /{1,3}(g|kg|litre)(d)(de)? *{1}/
        recognized_inputs.each_with_index do |input, index|
          recon_input = content.split()[input[:indexes][0]..input[:indexes][-1]].join(" ")
          quantity = content.match(/(\d{1,3}(\.|,)\d{1,2}|\d{1,3}) *((g|gramme|kg|kilo|kilogramme|tonne|t|l|litre|hectolitre|hl)(s)? *(par hectare|\/ *hectare|\/ *ha)?) *(de|d\'|du)? *(la|le)? *#{recon_input}/)
          sec_quantity = content.match(/#{recon_input} *(à|a|avec)? *(\d{1,3}(\.|,)\d{1,2}|\d{1,3}) *((gramme|g|kg|kilo|kilogramme|tonne|t|hectolitre|hl|litre|l)(s)? *(par hectare|\/ *hectare|\/ *ha)?)/)
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
          measure = get_measure(rate.to_f, unit, area)
          # If measure in mass or volume , and procedure can handle this type of indicators for its inputs and net dimension exists for specific input
          if [:mass, :volume].include? measure.base_dimension.to_sym and !Procedo::Procedure.find(procedure).parameters_of_type(:input).find {|inp| Matter.where("id = #{input[:key]}").first.of_expression(inp.filter)}.handler("net_#{measure.base_dimension}").nil? and !Matter.where("id = #{input[:key]}").first&.send("net_#{measure.base_dimension}").zero?
            # If it's not a per hectare distance
            if measure.repartition_unit.nil?
              measure = measure.in(Procedo::Procedure.find(procedure).parameters_of_type(:input).find {|inp| Matter.where("id = #{input[:key]}").first.of_expression(inp.filter)}.handler("net_#{measure.base_dimension}").unit.name)
              input[:rate] = {:value => measure.value.to_f, :unit => "net_#{measure.base_dimension}"}
            else 
              measure = measure.in(Procedo::Procedure.find(procedure).parameters_of_type(:input).find {|inp| Matter.where("id = #{input[:key]}").first.of_expression(inp.filter)}.handler(measure.dimension).unit.name)
              input[:rate] = {:value => measure.value.to_f, :unit => measure.dimension}
            end 
          else 
            input[:rate] = {:value => nil, :unit => :population}
          end 
        end
        return recognized_inputs
      end

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

      def redirect(parsed)
        if parsed[:retry] == 2
          return "cancel", nil, nil
        end
        unless parsed[:ambiguities].to_a.empty?
          return "ask_ambiguity", nil, parsed[:ambiguities][0]
        end
        parsed[:inputs].to_a.each do |input| 
        end 
        if parsed[:inputs].to_a.any? {|input| input[:rate][:value].nil?}
          sentence, optional = speak_input_rate(parsed)
          return "ask_input_rate", sentence, optional
        end
        return "save", speak_intervention(parsed), nil
      end
    end
  end
end
