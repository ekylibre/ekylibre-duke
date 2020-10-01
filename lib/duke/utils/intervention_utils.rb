module Duke
  module Utils
    class InterventionUtils < Duke::Utils::DukeParsing

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
            sentence += "#{input[:name]}, "
          end
        end
        sentence += "<br>&#8226 Date : #{params[:date].to_datetime.strftime("%d/%m/%Y - %H:%M")}"
        sentence += "<br>&#8226 Durée : #{params[:duration]} mins"
        return sentence.gsub(/, <br>&#8226/, "<br>&#8226")
      end

      def add_input_rate(content, recognized_inputs)
        # This function adds a 1 population quantity to every input that has been found
        # Next step could be to match this type of regex : /{1,3}(g|kg|litre)(d)(de)? *{1}/
        recognized_inputs.each_with_index do |input, index|
          recon_input = content.split()[input[:indexes][0]..input[:indexes][-1]].join(" ")
          quantity = content.match(/(\d{1,3}(\.|,)\d{1,2}|\d{1,3}) *((\bg\b|gramme|kg|kilo|kilogramme|tonne|t|l\b|litre|hectolitre|hl\b)(s)? *(par hectare|\/ *hectare|\/ *ha)?) *(de|d\'|du)? *(la|le)? *#{recon_input}/)
          sec_quantity = content.match(/#{recon_input} *(à|a|avec) *(\d{1,3}(\.|,)\d{1,2}|\d{1,3}) *((gramme|g|kg|kilo|kilogramme|tonne|t|hectolitre|litre)(s)? *(par hectare|\/ *hectare|\/ *ha))/)
          if quantity
            unit = quantity[4]
            rate = quantity[1].gsub(',','.')
            area = (true unless quantity[6].nil?)
          elsif sec_quantity
            unit = sec_quantity[5]
            rate = sec_quantity[2].gsub(',','.')
            area = (true unless quantity[7].nil?)
          else
            unit = :population
            rate = nil
            factor = nil
            area = nil
          end
          unless rate.nil?
            unit, factor = get_input_indicator(unit, input, area)
          end
          input[:rate] = {:value => rate, :unit => unit, :factor => factor}
        end
        return recognized_inputs
        # Matter.where('id = 93').first.indicators_list.include? (:net_mass)
      end

      def get_input_indicator(unit, input, area)
        if Matter.where("id = #{input[:key]}").first.indicators_list.include? (:net_mass)
          if unit.match(/(gramme|\bg\b)/)
            return :net_mass, 0.001 if area.nil?
            return :mass_area_density, 0.001
          elsif unit.match(/(kilo|kg)/)
            return :net_mass, 1 if area.nil?
            return :mass_area_density, 1
          elsif unit.match(/(tonne|\bt\b)/)
            return :net_mass, 1000 if area.nil?
            return :mass_area_density, 1000
          end
        end
        if Matter.where("id = #{input[:key]}").first.indicators_list.include? (:net_volume)
          if unit.match(/(litre|l\b)/)
            return :net_volume, 1 if area.nil?
            return :volume_area_density, 1
          elsif unit.match(/(hectolitre|hl\b)/)
            return :net_volume, 100 if area.nil?
            return :volume_area_density, 1
          end
        end
        return :population, 1
      end

      def redirect(parsed)
        unless parsed[:ambiguities].to_a.empty?
          return "ask_ambiguity", nil, parsed[:ambiguities][0]
        end
        return "save", speak_intervention(parsed), nil
      end
    end
  end
end
