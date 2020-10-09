module Duke
  module Utils
    class InterventionUtils < Duke::Utils::DukeParsing
      @@unit_to_human = {:net_mass => :kg, :net_volume => :litres, :mass_area_density => 'kg/ha', :volume_area_density => 'L/ha', :population => :unités}

      def speak_intervention(params)
        # Create validation sentence for InterventionSkill
        I18n.locale = :fra
        sentence = I18n.t("duke.interventions.save_intervention_#{rand(0...3)}")
        sentence += "<br>&#8226 Procédure : #{Procedo::Procedure.find(params[:procedure]).human_name}"
        unless params[:crop_groups].to_a.empty?
          sentence += "<br>&#8226 Groupements : "
          params[:crop_groups].each do |cg|
            sentence += "#{cg[:name]}, "
          end
        end
        unless params[:equipments].to_a.empty?
          sentence += "<br>&#8226 Equipement : "
          params[:equipments].each do |eq|
            sentence += "#{eq[:name]}, "
          end
        end
        unless params[:workers].to_a.empty?
          sentence += "<br>&#8226 Travailleurs : "
          params[:workers].each do |worker|
            sentence += "#{worker[:name]}, "
          end
        end
        unless params[:inputs].to_a.empty?
          sentence += "<br>&#8226 Intrants : "
          params[:inputs].each do |input|
            sentence += "#{input[:name]} (#{input[:rate][:value].to_f*input[:rate][:factor]} #{@@unit_to_human[input[:rate][:unit].to_sym]}), "
          end
        end
        sentence += "<br>&#8226 Date : #{params[:date].to_datetime.strftime("%d/%m/%Y - %H:%M")}"
        sentence += "<br>&#8226 Durée : #{params[:duration]} mins"
        return sentence.gsub(/, <br>&#8226/, "<br>&#8226")
      end

      def speak_input_rate(params)
        # Creates "Combien de kg de bouillie bordelaise ont été utilisés ? "
        # Return the sentence, and the index of the destination inside params[:destination] to transfer as an optional value to IBM
        I18n.locale = :fra
        params[:inputs].each_with_index do |input, index|
          if input[:rate][:value].nil?
            sentence = I18n.t("duke.interventions.how_much_inputs_#{rand(0...2)}", input: input[:name], unit: @@unit_to_human[input[:rate][:unit].to_sym])
            return sentence, index
          end
        end
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

      def add_input_rate(content, recognized_inputs)
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
          unit, factor = get_input_indicator(unit, input, area)
          input[:rate] = {:value => rate, :unit => unit, :factor => factor}
        end
        return recognized_inputs
      end

      def get_input_indicator(unit, input, area)
        if Matter.where("id = #{input[:key]}").first.has_indicator?(:net_mass)
          if unit == :population
            return :net_mass, 1
          elsif unit.match(/(kilo|kg)/)
            return :net_mass, 1 if area.nil?
            return :mass_area_density, 1
          elsif unit.match(/(gramme|g)/)
            return :net_mass, 0.001 if area.nil?
            return :mass_area_density, 0.001
          elsif unit.match(/(tonne)/) || unit == "t"
            return :net_mass, 1000 if area.nil?
            return :mass_area_density, 1000
          end
        end
        if Matter.where("id = #{input[:key]}").first.has_indicator?(:net_volume)
          if unit == :population
            return :net_volume, 1
          elsif unit.match(/(hectolitre|hl)/)
            return :net_volume, 100 if area.nil?
            return :volume_area_density, 100
          elsif unit.match(/(litre|l)/)
            return :net_volume, 1 if area.nil?
            return :volume_area_density, 1
          end
        end
        return :population, 1
      end

      def redirect(parsed)
        if parsed[:retry] == 2
          return "cancel", nil, nil
        end
        unless parsed[:ambiguities].to_a.empty?
          return "ask_ambiguity", nil, parsed[:ambiguities][0]
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
