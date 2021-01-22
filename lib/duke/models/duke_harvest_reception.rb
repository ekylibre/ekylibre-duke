module Duke
  module Models
    class DukeHarvestReception < Duke::Models::DukeArticle

      def speak_harvest_reception(params)
        # Create validation sentence for HarvestReceptionSkill
        sentence = I18n.t("duke.harvest_reception.ask.save_harvest_reception_#{rand(0...2)}")
        unless params[:crop_groups].to_a.empty?
          sentence+= "<br>&#8226 #{I18n.t("duke.interventions.group")} : "
          params[:crop_groups].each do |crop_group|
            sentence += "#{crop_group[:area].to_s}% #{crop_group[:name]}, "
          end
        end
        unless params[:plant].to_a.empty?
          sentence+= "<br>&#8226 #{I18n.t("duke.interventions.plant")} : "
          params[:plant].each do |target|
            sentence += "#{target[:area].to_s}% #{target[:name]}, "
          end
        end
        sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.quantity")} : #{params[:parameters]['quantity']['rate'].to_s} #{params[:parameters]['quantity']['unit']}"
        sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.tavp")} : #{params[:parameters]['tav'].to_s} % vol"
        sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.destination")} : "
        params[:destination].each do |destination|
          sentence+= destination[:name]
          sentence+= " (#{destination[:quantity].to_s} hl), " if destination.key?('quantity')
        end
        unless !params.key?("press")
          sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.press")} : "
          params[:press].each do |press|
            sentence+= press[:name]
            sentence+= " (#{press[:quantity].to_s} hl), " if press.key?('quantity')
          end
        end
        sentence+= "<br>&#8226 #{I18n.t("duke.interventions.date")} : #{params[:date].to_datetime.strftime("%d/%m/%Y - %H:%M")}"
        unless params[:parameters]['temperature'].nil?
          sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.temp")} : #{params[:parameters]['temperature']} °C"
        end
        unless params[:parameters]['sanitarystate'].nil?
          sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.sanitary_specified")}"
        end
        unless params[:parameters]['ph'].nil?
          sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.ph")} : #{params[:parameters]['ph']}"
        end
        unless params[:parameters]['h2so4'].nil?
          sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.total_acidity")} : #{params[:parameters]['h2so4']} g H2SO4/L"
        end
        unless params[:parameters]['malic'].nil?
          sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.malic_acid")} : #{params[:parameters]['malic']} g/L"
        end
        unless params[:parameters]['amino_nitrogen'].nil?
          sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.amino_n")} : #{params[:parameters]['amino_nitrogen']} mg/L"
        end
        unless params[:parameters]['ammoniacal_nitrogen'].nil?
          sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.ammoniacal_n")} : #{params[:parameters]['ammoniacal_nitrogen']} mg/L"
        end
        unless params[:parameters]['assimilated_nitrogen'].nil?
          sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.assimilated_n")} : #{params[:parameters]['assimilated_nitrogen']} mg/L"
        end
        unless params[:parameters]['pressing_tavp'].nil?
          sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.press_tavp")} : #{params[:parameters]['pressing_tavp'].to_s} % vol "
        end
        unless params[:parameters]['complementary'].nil?
          if params[:parameters]['complementary'].key?('ComplementaryDecantation')
            sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.decant_time")} : #{params[:parameters]['complementary']['ComplementaryDecantation'].delete("^0-9")} mins"
          end
          if params[:parameters]['complementary'].key?('ComplementaryTrailer')
            sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.transportor")} : #{params[:parameters]['complementary']['ComplementaryTrailer']}"
          end
          if params[:parameters]['complementary'].key?('ComplementaryTime')
            sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.transport_dur")} : #{params[:parameters]['complementary']['ComplementaryTime'].delete("^0-9")} mins"
          end
          if params[:parameters]['complementary'].key?('ComplementaryDock')
            sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.reception_dock")} : #{params[:parameters]['complementary']['ComplementaryDock']}"
          end
          if params[:parameters]['complementary'].key?('ComplementaryNature')
            sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.vendange_nature")} : #{I18n.t('labels.'+params[:parameters]['complementary']['ComplementaryNature'])}"
          end
          if params[:parameters]['complementary'].key?('ComplementaryLastLoad')
            sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.last_load")}"
          end
        end
        return sentence.gsub(/, <br>&#8226/, "<br>&#8226")
      end

      def speak_destination_hl(params)
        # Creates "How much hectoliters in Cuve 1 ?"
        # Return the sentence, and the index of the destination inside params[:destination] to transfer as an optional value to IBM
        sentence = I18n.t("duke.harvest_reception.ask.how_much_to_#{rand(0...2)}")
        params[:destination].each_with_index do |cuve, index|
          unless cuve.key?("quantity")
            sentence += cuve[:name]
            return sentence, index
          end
        end
      end

      def speak_pressing_hl(params)
        # Creates "How much hectoliters in Press 1 ?"
        # Return the sentence, and the index of the destination inside params[:destination] to transfer as an optional value to IBM
        sentence = I18n.t("duke.harvest_reception.ask.how_much_to_#{rand(0...2)}")
        params[:press].each_with_index do |press, index|
          unless press.key?("quantity")
            sentence += press[:name]
            return sentence, index
          end
        end
      end

      def create_analysis_attributes(parsed)
        # Creates additional analysis attributes
        attributes =    {"0"=>{"_destroy"=>"false", "indicator_name"=>"estimated_harvest_alcoholic_volumetric_concentration", "measure_value_value"=> parsed[:parameters]['tav'], "measure_value_unit"=>"volume_percent"}}
        attributes[1] = {"_destroy"=>"false", "indicator_name"=>"potential_hydrogen", "decimal_value"=> parsed[:parameters]['ph'] } unless parsed[:parameters]['ph'].nil?
        attributes[2] = {"_destroy"=>"false", "indicator_name"=>"temperature", "measure_value_value"=> parsed[:parameters]['temperature'], "measure_value_unit"=>"celsius"} unless parsed[:parameters]['temperature'].nil?
        attributes[3] = {"_destroy"=>"false", "indicator_name"=>"assimilated_nitrogen_concentration", "measure_value_value"=> parsed[:parameters]['assimilated_nitrogen'], "measure_value_unit"=>"milligram_per_liter"} unless parsed[:parameters]['assimilated_nitrogen'].nil?
        attributes[4] = {"_destroy"=>"false", "indicator_name"=>"amino_nitrogen_concentration", "measure_value_value"=> parsed[:parameters]['amino_nitrogen'], "measure_value_unit"=>"milligram_per_liter"} unless parsed[:parameters]['amino_nitrogen'].nil?
        attributes[5] = {"_destroy"=>"false", "indicator_name"=>"ammoniacal_nitrogen_concentration", "measure_value_value"=> parsed[:parameters]['ammoniacal_nitrogen'], "measure_value_unit"=>"milligram_per_liter"} unless parsed[:parameters]['ammoniacal_nitrogen'].nil?
        attributes[6] = {"_destroy"=>"false", "indicator_name"=>"total_acid_concentration", "measure_value_value"=>parsed[:parameters]['h2so4'], "measure_value_unit"=>"gram_per_liter"} unless parsed[:parameters]['h2so4'].nil?
        attributes[7] = {"_destroy"=>"false", "indicator_name"=>"malic_acid_concentration", "measure_value_value"=>parsed[:parameters]['malic'], "measure_value_unit"=>"gram_per_liter"} unless parsed[:parameters]['malic'].nil?
        attributes[8] = {"_destroy"=>"false", "indicator_name"=>"sanitary_vine_harvesting_state", "string_value"=> parsed[:parameters]['sanitarystate']} unless parsed[:parameters]['sanitarystate'].nil?
        attributes[9] = {"measure_value_unit" =>"volume_percent","indicator_name" => "estimated_pressed_harvest_alcoholic_volumetric_concentration", "measure_value_value" => parsed[:parameters]['pressing_tavp']} unless parsed[:parameters]['pressing_tavp'].nil?
        return attributes
      end

      def create_incoming_harvest_attr(dic, parsed)
        # Creates additional incoming harveset attributes
        unless parsed[:parameters]['pressing'].nil?
          dic[:pressing_schedule] = parsed[:parameters]['pressing']['program']
          unless parsed[:parameters]['pressing']['hour'].nil?
            dic[:pressing_started_at] = parsed[:parameters]['pressing']['hour'].to_datetime.strftime("%H:%M")
          end
        end
        unless parsed[:parameters]['complementary'].nil?
          if parsed[:parameters]['complementary'].key?('ComplementaryDecantation')
            dic[:sedimentation_duration] = parsed[:parameters]['complementary']['ComplementaryDecantation'].delete("^0-9")
          end
          if parsed[:parameters]['complementary'].key?('ComplementaryTrailer')
            dic[:vehicle_trailer] = parsed[:parameters]['complementary']['ComplementaryTrailer']
          end
          if parsed[:parameters]['complementary'].key?('ComplementaryTime')
            dic[:harvest_transportation_duration] = parsed[:parameters]['complementary']['ComplementaryTime'].delete("^0-9")
          end
          if parsed[:parameters]['complementary'].key?('ComplementaryDock')
            dic[:harvest_dock] = parsed[:parameters]['complementary']['ComplementaryDock']
          end
          if parsed[:parameters]['complementary'].key?('ComplementaryNature')
            dic[:harvest_nature] = parsed[:parameters]['complementary']['ComplementaryNature']
          end
          if parsed[:parameters]['complementary'].key?('ComplementaryLastLoad')
            dic[:last_load] = "true"
          end
        end
        return dic
      end

      def extract_quantity(content, parameters)
        # Extracting quantity data
        quantity_regex = '(\d{1,5}(\.|,)\d{1,2}|\d{1,5}) *(kilo|kg|hecto|expo|texto|hl|t\b|tonne)'
        quantity = content.match(quantity_regex)
        if quantity
          content[quantity[0]] = ""
          if quantity[3].match('(kilo|kg)')
            unit = "kg"
          elsif quantity[3].match('(hecto|hl|texto|expo)')
            unit = "hl"
          else
            unit = "t"
          end
          parameters['quantity'] = {"rate" => quantity[1].gsub(',','.').to_f, "unit" => unit} # rate is the first capturing group
        else
          parameters['quantity'] = nil
        end
        return parameters
      end

      def extract_conflicting_degrees(content, parameters)
        # Conflicts between TAV "degré" and temperature "degré", so we need to check first for explicit values
        second_tav_regex = '(degré d\'alcool|alcool|degré|tavp|t avp2|tav|avp|t svp|pourcentage|t avait) *(jus de presse)? *(est|était)? *(égal +(a *|à *)?|= *|de *|à *)?(\d{1,2}(\.|,)\d{1,2}|\d{1,2}) *(degré)?'
        second_temp_regex = '(température|temp) *(est|était)? *(égal *|= *|de *|à *)?(\d{1,2}(\.|,)\d{1,2}|\d{1,2}) *(degré)?'
        tav = content.match(second_tav_regex)
        if tav
          content[tav[0]] = ""
          parameters['tav'] = tav[6].gsub(',','.') # rate is the fifth capturing group
        end
        temp = content.match(second_temp_regex)
        if temp
          content[temp[0]] = ""
          parameters['temperature'] = temp[4].gsub(',','.') # temperature is the fourth capturing group
        end
        return parameters
      end

      def extract_tav(content, parameters)
        # Extracting tav data
        tav_regex = '(\d{1,2}|\d{1,2}(\.|,)\d{1,2}) ((degré(s)?|°|%)|(de|en|d\')? *(tavp|t avp|tav|(t)? *avp|(t)? *svp|t avait|thé avait|thé à l\'épée|alcool|(entea|mta) *vp))'
        tav = content.match(tav_regex)
        unless parameters.key?('tav')
          if tav
            content[tav[0]] = ""
            parameters['tav'] = tav[1].gsub(',','.') # rate is the first capturing group
          else
            parameters['tav'] = nil
          end
        end
        return parameters
      end

      def extract_temp(content, parameters)
        # Extracting temperature data
        temp_regex = '(\d{1,2}|\d{1,2}(\.|,)\d{1,2}) +(degré|°)'
        temp = content.match(temp_regex)
        unless parameters.key?('temperature')
          if temp
            content[temp[0]] = ""
            parameters['temperature'] = temp[1].gsub(',','.') # temperature is the first capturing group
          else
            parameters['temperature'] = nil
          end
        end
      end

      def extract_ph(content, parameters)
        # Extracting ph data
        ph_regex = '(\d{1,2}|\d{1,2}(\.|,)\d{1,2}) +(de +)?(ph|péage)'
        second_ph_regex = '((ph|péage) *(est|était)? *(égal *(a|à)? *|= ?|de +|à +)?)(\d{1,2}(\.|,)\d{1,2}|\d{1,2})'
        ph = content.match(ph_regex)
        second_ph = content.match(second_ph_regex)
        if ph
          content[ph[0]] = ""
          parameters['ph'] = ph[1].gsub(',','.') # ph is the first capturing group
        elsif second_ph
          content[second_ph[0]] = ""
          parameters['ph'] = second_ph[6].gsub(',','.') # ph is the third capturing group
        else
          parameters['ph'] = nil
        end
      end

      def extract_amino_nitrogen(content, parameters)
        # Extracting nitrogen data
        nitrogen_regex = '(\d{1,3}|\d{1,3}(\.|,)\d{1,2}) +(mg|milligramme)?.?(par l|\/l|par litre)? ?+(d\'|de|en)? *azote aminé'
        second_nitrogen_regex = '(azote aminé *(est|était)? *(égal +|= ?|de +)?(à)? *)(\d{1,3}(\.|,)\d{1,2}|\d{1,3})'
        nitrogen = content.match(nitrogen_regex)
        second_nitrogen = content.match(second_nitrogen_regex)
        if nitrogen
          content[nitrogen[0]] = ""
          parameters['amino_nitrogen'] = nitrogen[1].gsub(',','.') # nitrogen is the first capturing group
        elsif second_nitrogen
          content[second_nitrogen[0]] = ""
          parameters['amino_nitrogen'] = second_nitrogen[5].gsub(',','.') # nitrogen is the seventh capturing group
        else
          parameters['amino_nitrogen'] = nil
        end
      end

      def extract_ammoniacal_nitrogen(content, parameters)
        # Extracting nitrogen data
        nitrogen_regex = '(\d{1,3}|\d{1,3}(\.|,)\d{1,2}) +(mg|milligramme)?.?(par l|\/l|par litre)? ?+(d\'|de|en)? *azote ammonia'
        second_nitrogen_regex = '(azote (ammoniacal|ammoniaque) *(est|était)? *(égal +|= ?|de +)?(à)? *)(\d{1,3}(\.|,)\d{1,2}|\d{1,3})'
        nitrogen = content.match(nitrogen_regex)
        second_nitrogen = content.match(second_nitrogen_regex)
        if nitrogen
          content[nitrogen[0]] = ""
          parameters['ammoniacal_nitrogen'] = nitrogen[1].gsub(',','.') # nitrogen is the first capturing group
        elsif second_nitrogen
          content[second_nitrogen[0]] = ""
          parameters['ammoniacal_nitrogen'] = second_nitrogen[6].gsub(',','.') # nitrogen is the seventh capturing group
        else
          parameters['ammoniacal_nitrogen'] = nil
        end
      end

      def extract_assimilated_nitrogen(content, parameters)
        # Extracting nitrogen data
        nitrogen_regex = '(\d{1,3}|\d{1,3}(\.|,)\d{1,2}) +(mg|milligramme)?.?(par l|\/l|par litre)? ?+(d\'|de|en)? ?+(azote *(assimilable)?|sel d\'ammonium|substance(s)? azotée)'
        second_nitrogen_regex = '((azote *(assimilable)?|sel d\'ammonium|substance azotée) *(est|était)? *(égal +|= ?|de +)?(à)? *)(\d{1,3}(\.|,)\d{1,2}|\d{1,3})'
        nitrogen = content.match(nitrogen_regex)
        second_nitrogen = content.match(second_nitrogen_regex)
        if nitrogen
          content[nitrogen[0]] = ""
          parameters['assimilated_nitrogen'] = nitrogen[1].gsub(',','.') # nitrogen is the first capturing group
        elsif second_nitrogen
          content[second_nitrogen[0]] = ""
          parameters['assimilated_nitrogen'] = second_nitrogen[7].gsub(',','.') # nitrogen is the seventh capturing group
        else
          parameters['assimilated_nitrogen'] = nil
        end
      end

      def extract_sanitarystate(content, parameters)
        # Extracting sanitary state data
        sanitary_regex = '(état sanitaire) *(.*?)(destination|tav|\d{1,3} *(kg|hecto|kilo|hl|tonne)|cuve|degré|température|pourcentage|alcool|ph|péage|azote|acidité|malique|manuel|mécanique|hectare|$)'
        sanitary_match = content.match(sanitary_regex)
        sanitarystate = ""
        if sanitary_match
          sanitarystate += sanitary_match[2]
          content[sanitary_match[1]] = ""
          content[sanitary_match[2]] = ""
        end
        if content.include? "sain " || content.include?("sein")
          sanitarystate += "sain "
        end
        if content.include?("correct")
          content["correct"] = ""
          sanitarystate += "correct "
        end
        if content.include?("normal")
          content["normal"] = ""
          sanitarystate += "normal "
        end
        if content.include?("botrytis") || content.include?("beau titre is")
          sanitarystate += "botrytis "
        end
        if content.include?("oidium") || content.include?("oïdium")
          content["dium"] = ""
          sanitarystate += "oïdium "
        end
        if content.include? "pourriture"
          content["pourriture"] = ""
          sanitarystate += "pourriture "
        end
        state = sanitarystate if sanitarystate != "" || nil
        parameters['sanitarystate'] = state
      end

      def extrat_h2SO4(content, parameters)
        # Extracting H2SO4 data
        h2so4_regex = '(\d{1,3}|\d{1,3}(\.|,)\d{1,2}) +(g|gramme)?.? *(par l|\/l|par litre)? ?+(d\'|de|en)? ?+(acidité|acide|h2so4)'
        second_h2so4_regex = '(acide|acidité|h2so4) *(est|était)? *(égal.? *(a|à)?|=|de|à|a)? *(\d{1,3}(\.|,)\d{1,2}|\d{1,3})'
        h2so4 = content.match(h2so4_regex)
        second_h2so4 = content.match(second_h2so4_regex)
        if h2so4
          content[h2so4[0]] = ""
          parameters['h2so4'] = h2so4[1].gsub(',','.') # h2so4 is the first capturing group
        elsif second_h2so4
          content[second_h2so4[0]] = ""
          parameters['h2so4'] = second_h2so4[5].gsub(',','.') # h2so4 is the third capturing group
        else
          parameters['h2so4'] = nil
        end
      end

      def extract_malic(content, parameters)
        # Extracting malic acid data
        malic_regex = '(\d{1,3}|\d{1,3}(\.|,)\d{1,2}) *(g|gramme)?.?(par l|\/l|par litre)? *(d\'|de|en)? *(acide?) *(malique|malic)'
        second_malic_regex = '((acide *)?(malic|malique) *(est|était)? *(égal +|= ?|de +|à +)?)(\d{1,3}(\.|,)\d{1,2}|\d{1,3})'
        malic = content.match(malic_regex)
        second_malic = content.match(second_malic_regex)
        if malic
          content[malic[0]] = ""
          parameters['malic'] = malic[1].gsub(',','.') # malic is the first capturing group
        elsif second_malic
          content[second_malic[0]] = ""
          parameters['malic'] = second_malic[6].gsub(',','.') # malic is the third capturing group
        else
          parameters['malic'] = nil
        end
      end

      def extract_pressing(content, parameters)
        # pressing values can only be added by clicking on a button, and are empty by default
        parameters['pressing'] = nil
      end

      def extract_pressing_tavp(content, parameters)
        # pressing values can only be added by clicking on a button, and are empty by default
        parameters['pressing_tavp'] = nil
      end

      def extract_complementary(content, parameters)
        # pressing values can only be added by clicking on a button, and are empty by default
        parameters['complementary'] = nil
      end

      def extract_plant_area(content, targets, crop_groups)
        # Extracts a plant area from a sentence
        [targets, crop_groups].each do |crops|
          crops.each do |target|
            # Find the string that matched, ie "Jeunes Plants" when index is [3,4], then look for it in regex
            recon_target = content.split(/[\s\']/)[target[:indexes][0]..target[:indexes][-1]].join(" ")
            first_area_regex = /(\d{1,2}) *(%|pour( )?cent(s)?) *(de *(la|l\')?|du|des|sur|à|a|au)? #{recon_target}/
            second_area_regex = /(\d{1,3}|\d{1,3}(\.|,)\d{1,2}) *((hect)?are(s)?) *(de *(la|l\')?|du|des|sur|à|a|au)? #{recon_target}/
            first_area = content.match(first_area_regex)
            second_area = content.match(second_area_regex)
            # If we found a percentage, append it as the area value
            if first_area
              target[:area] = first_area[1].to_i
            # If we found an area, convert it in percentage of Total area and append it
            elsif second_area && !Plant.find_by(id: target[:key]).nil?
              target[:area] = 100
              if second_area[3].match(/hect/)
                area = second_area[1].gsub(',','.').to_f
              else
                area = second_area[1].gsub(',','.').to_f/100
              end
              whole_area = Plant.find_by(id: target[:key])&.net_surface_area&.to_f
              unless whole_area.zero?
                target[:area] = [(100*area/whole_area).to_i, 100].min
              end
            else
              # Otherwise Area = 100%
              target[:area] = 100
            end
          end
        end
      end

      def redirect(parsed)
        # Find what we should ask the user next for an harvest reception
        if parsed[:retry] == 2
          # If user failed to answer correctly twice, we cancel
          return "cancel", nil, nil
        end
        unless parsed[:ambiguities].to_a.empty?
          # If there's an ambiguity, we solve it
          return "ask_ambiguity", nil, parsed[:ambiguities][0]
        end
        if parsed[:plant].to_a.empty? && parsed[:crop_groups].to_a.empty?
          # If there's not plant, we ask for it
          return "ask_plant", nil, nil
        end
        if parsed[:parameters]['quantity'].nil?
          # Same for quantity
          return "ask_quantity", nil, nil
        end
        if parsed[:destination].to_a.empty?
          # Same for destination
          return "ask_destination", nil, nil
        end
        # If we have more that one destination, and no quantity specified for at least one, ask for it
        if parsed[:destination].to_a.length > 1 and parsed[:destination].any? {|dest| !dest.key?("quantity")}
          sentence, optional = speak_destination_hl(parsed)
          return "ask_destination_quantity", sentence, optional
        end
        # If theres more than one press without quantity, we ask for quantity in each of them
        unless !parsed.key?(:press)
          if parsed[:press].to_a.length > 1 and parsed[:press].any? {|press| !press.key?("quantity")}
            sentence, optional = speak_pressing_hl(parsed)
            return "ask_pressing_quantity", sentence, optional
          end
        end
        if parsed[:parameters]["tav"].nil?
          # If tav wasn't given, ask for it
          return "ask_tav", nil, nil
        end
        # Otherwise save harvest reception
        return "save", speak_harvest_reception(parsed)
      end

      def concatenate_analysis(parameters, new_parameters)
        # For harvesting receptions, concatenate previous found parameters and new one given by the user
        final_parameters =  new_parameters.dup.map(&:dup).to_h
        new_parameters.each do |key, value|
          if ['key','tav'].include?(key)
            final_parameters[key] = parameters[key]
          elsif value.nil?
            unless parameters[key].nil?
              final_parameters[key] = parameters[key]
            end
          end
        end
        return final_parameters
      end

      def extract_reception_parameters(content)
        # Extracting all regex parameters for an harvest reception
        parameters = {}
        extract_conflicting_degrees(content, parameters)
        extract_quantity(content, parameters)
        extract_tav(content, parameters)
        extract_temp(content, parameters)
        extract_ph(content, parameters)
        extract_amino_nitrogen(content, parameters)
        extract_ammoniacal_nitrogen(content, parameters)
        extract_assimilated_nitrogen(content, parameters)
        extract_sanitarystate(content, parameters)
        extract_malic(content, parameters)
        extrat_h2SO4(content, parameters)
        extract_pressing(content, parameters)
        extract_complementary(content, parameters)
        extract_pressing_tavp(content,parameters)
        return parameters
      end

      def unit_to_hectoliter(value, unit)
        # Converts kg or T to hectoliter
        if unit == "hl"
          return sprintf('%.3f', value.to_f)
        elsif unit == "kg"
          return sprintf('%.3f', value.to_f/130)
        else
          return sprintf('%.3f', value.to_f/0.130)
        end
      end

    end
  end
end
