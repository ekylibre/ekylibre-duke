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
          input[:rate] = {:value => 1, :unit => "population", "found" => "Nothing"}
        end
        return recognized_inputs
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
