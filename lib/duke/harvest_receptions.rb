module Duke
  class HarvestReceptions < Duke::Utils::HarvestReceptionUtils

    def handle_parse_sentence(params)
      Ekylibre::Tenant.switch params['tenant'] do
        targets = []
        crop_groups = []
        destination = []
        date, user_input = extract_date(clear_string(params[:user_input]))
        user_input, parameters = extract_reception_parameters(user_input)
        parsed = {:targets => targets,
                  :crop_groups => crop_groups,
                  :destination => destination,
                  :parameters => parameters,
                  :date => date,
                  :user_input => params[:user_input],
                  :retry => 0}
        extract_user_specifics(user_input, parsed)
        targets, crop_groups = extract_plant_area(user_input, targets, crop_groups)
        parsed[:ambiguities] = find_ambiguity(parsed, user_input)
        # Find if crucials parameters haven't been given, to ask again to the user
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :asking_again => what_next, :sentence => sentence, :optional => optional}
      end
    end

    def handle_parse_parameter(params)
      parsed = params[:parsed]
      parameter = params[:parameter]
      value = extract_number_parameter(params[parameter], params[:user_input])
      if value.nil?
        # If we couldn't find one, we cancel the functionnality
        parsed[:retry] += 1
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :asking_again => what_next, :sentence => sentence, :optional => optional}
      end
      # If we are parsing a quantity, we search for an unit inside the user input
      if parameter == "quantity"
        if params[:user_input].match('(?i)(kg|kilo)')
          unit = 'kg'
        elsif params[:user_input].match('(?i)\d *t\b|tonne')
          unit = 't'
        else
          unit = 'hl'
        end
        parsed[:parameters][parameter] = {:rate => value.to_f, :unit => unit }
      else
        parsed[:parameters][parameter] = value
      end
      parsed[:user_input] += " - #{params[:user_input]}"
      parsed[:retry] = 0
      what_next, sentence, optional = redirect(parsed)
      return  { :parsed => parsed, :asking_again => what_next, :sentence => sentence, :optional => optional}
    end

    def handle_modify_quantity_tav(params)
      parsed = params[:parsed]
      new_params = {}
      content = clear_string(params[:user_input])
      content, new_params = extract_quantity(content, new_params)
      content, new_params = extract_conflicting_degrees(content, new_params)
      content, new_params = extract_tav(content, new_params)
      unless new_params['quantity'].nil?
        parsed[:parameters]['quantity'] = new_params['quantity']
      end
      unless new_params['tav'].nil?
        parsed[:parameters]['tav'] = new_params['tav']
      end
      parsed[:user_input] += " - #{params[:user_input]}"
      what_next, sentence, optional = redirect(parsed)
      return  { :parsed => parsed, :asking_again => what_next, :sentence => sentence, :optional => optional}
    end

    def handle_modify_date(params)
      parsed = params[:parsed]
      user_input = clear_string(params[:user_input])
      date, user_input = extract_date(user_input)
      parsed[:date] = choose_date(date, parsed[:date])
      parsed[:user_input] = params[:parsed][:user_input] << ' - ' << params[:user_input]
      what_next, sentence, optional = redirect(parsed)
      return  { :parsed => parsed, :asking_again => what_next, :sentence => sentence, :optional => optional}
    end

    def handle_parse_destination_quantity(params)
      parsed = params[:parsed]
      parameter = params[:parameter]
      value = extract_number_parameter(params[parameter], params[:user_input])
      if value.nil?
        parsed[:retry] += 1
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :asking_again => what_next, :sentence => sentence, :optional => optional}
      end
      parsed[:destination][params[:optional]][:quantity] = value
      parsed[:user_input] += " - (Quantité) #{params[:user_input]}"
      parsed[:retry] = 0
      what_next, sentence, optional = redirect(parsed)
      return  { :parsed => parsed, :asking_again => what_next, :sentence => sentence, :optional => optional}
    end

    def handle_parse_targets(params)
      parsed = params[:parsed]
      Ekylibre::Tenant.switch params['tenant'] do
        targets, crop_groups = [], []
        user_input = clear_string(params[:user_input])
        new_parsed = {:targets => targets,
                      :crop_groups => crop_groups,
                      :date => parsed[:date]}
        extract_user_specifics(user_input, new_parsed)
        targets, crop_groups = extract_plant_area(user_input, targets, crop_groups)
        # If there's no new Target/Crop_group, But a percentage, it's the new area % foreach previous target
        if crop_groups.empty? and targets.empty?
          pct_regex = user_input.match(/(\d{1,2}) *(%|pour( )?cent(s)?)/)
          if pct_regex
            parsed[:crop_groups].to_a.each { |crop_group| crop_group[:area] = pct_regex[1]}
            parsed[:targets].to_a.each { |target| target[:area] = pct_regex[1]}
          end
        else
          parsed[:targets] = new_parsed[:targets]
          parsed[:crop_groups] = new_parsed[:crop_groups]
          parsed[:ambiguities] = find_ambiguity(new_parsed, user_input)
        end
      end
      parsed[:user_input] += " - (Cibles) #{params[:user_input]}"
      what_next, sentence, optional = redirect(parsed)
      if what_next == params[:current_asking]
        parsed[:retry] += 1
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :asking_again => what_next, :sentence => sentence, :optional => optional}
      end
      parsed[:retry] = 0
      return  { :parsed => parsed, :asking_again => what_next, :sentence => sentence, :optional => optional}
    end

    def handle_parse_destination(params)
      parsed = params[:parsed]
      Ekylibre::Tenant.switch params['tenant'] do
        destination = []
        user_input = clear_string(params[:user_input]).gsub("que","cuve")
        new_parsed = {:destination => destination,
                      :date => parsed[:date]}
        extract_user_specifics(user_input, new_parsed)
        parsed[:destination] = new_parsed[:destination]
        parsed[:ambiguities] = find_ambiguity(new_parsed, user_input)
      end
      parsed[:user_input] += ' (Destination) ' << params[:user_input]
      what_next, sentence, optional = redirect(parsed)
      if what_next == params[:current_asking] and optional == params[:optional]
        parsed[:retry] += 1
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :asking_again => what_next, :sentence => sentence, :optional => optional}
      end
      parsed[:retry] = 0
      return  { :parsed => parsed, :asking_again => what_next, :sentence => sentence, :optional => optional}
    end

    def handle_add_other(params)
      parsed = params[:parsed]
      what_next, sentence, optional = redirect(parsed)
      return  { :parsed => params[:parsed], :asking_again => what_next, :sentence => sentence, :optional => optional}
    end

    def handle_parse_disambiguation(params)
      parsed = params[:parsed]
      ambElement = params[:optional][-2]
      ambType, ambArray = parsed.find { |key, value| value.is_a?(Array) and value.any? { |subhash| subhash[:name] == ambElement[:name]}}
      ambHash = ambArray.find {|hash| hash[:name] == ambElement[:name]}
      begin
        chosen_one = eval(params[:user_input])
        ambHash[:name] = chosen_one["name"]
        ambHash[:key] = chosen_one["key"]
      rescue
        if params[:user_input] == "Tous"
          params[:optional].each_with_index do |ambiguate, index|
            # Last two values are the one that's already added, and the inSentenceName value -> useless
            unless [1,2].include?(params[:optional].length - index)
              hashClone = ambHash.clone()
              hashClone[:name] = ambiguate[:name].to_s
              hashClone[:key] = ambiguate[:key].to_s
              ambArray.push(hashClone)
            end
          end
        elsif params[:user_input] == "Aucun"
          ambArray.delete(ambHash)
        end
      ensure
        parsed[:ambiguities].shift
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :asking_again => what_next, :sentence => sentence, :optional => optional}
      end
    end

    def handle_add_analysis(params)
      user_input, new_parameters = extract_reception_parameters(clear_string(params[:user_input]))
      if new_parameters['tav'].nil?
        pressing_tavp = nil
      else
        pressing_tavp = new_parameters['tav']
      end
      new_parameters = concatenate_analysis(params[:parsed][:parameters], new_parameters)
      new_parameters['pressing_tavp'] = pressing_tavp
      params[:parsed][:parameters] = new_parameters
      params[:parsed][:user_input] += " - (Analyse) #{params[:user_input]}"
      # Find if crucials parameters haven't been given, to ask again to the user
      what_next, sentence, optional = redirect(params[:parsed])
      return  { :parsed => params[:parsed], :asking_again => what_next, :sentence => sentence, :optional => optional}
    end

    def handle_add_pressing(params)
      new_parameters = params[:parsed][:parameters]
      decantation_time, user_input = extract_decantation_time(clear_string(params[:user_input]))
      decantation_input = user_input.clone
      pressing_date, user_input = extract_hour(user_input)
      # If decant_user_input == user_input => we didn't find anything to provide the hour, so pressing date is nil
      if decantation_input.gsub(/\s+/, "") == user_input.gsub(/\s+/, "")
        pressing_date = nil
      end
      useless_pressing_words = [/d(e|é)marrage/, /d(é|e)but(er|é|e|a)*/, /commenc(er|é|e|a)/, /\b(à|a|dès|vers|démarr(é|er|e))\b/]
      useless_pressing_words.each do |word|
        user_input = user_input.gsub(word, "")
      end
      new_parameters['pressing'] = {'hour' => pressing_date, 'program' => user_input.gsub(/\s+/, " ")}
      params[:parsed][:parameters] = new_parameters
      params[:parsed][:user_input] += " - (Pressurage) #{params[:user_input]}"
      unless decantation_time == 0
        if params[:parsed][:parameters]['complementary'].nil?
          params[:parsed][:parameters][:complementary] = {'ComplementaryDecantation' => decantation_time.to_s}
        else
          params[:parsed][:parameters][:complementary]['ComplementaryDecantation'] = decantation_time.to_s
        end
      end
      # Find if crucials parameters haven't been given, to ask again to the user
      what_next, sentence, optional = redirect(params[:parsed])
      return  { :parsed => params[:parsed], :asking_again => what_next, :sentence => sentence, :optional => optional}
    end

    def handle_add_complementary(params)
      if params[:parsed][:parameters][:complementary].nil?
        complementary = {}
      else
        complementary = params[:parsed][:parameters][:complementary]
      end
      complementary[params[:parameter]] = params[:user_input]
      params[:parsed][:parameters][:complementary] = complementary
      # Find if crucials parameters haven't been given, to ask again to the user
      what_next, sentence, optional = redirect(params[:parsed])
      return  { :parsed => params[:parsed], :asking_again => what_next, :sentence => sentence, :optional => optional}
    end

    def handle_save_harvest_reception(params)
      parsed = params[:parsed]
      Ekylibre::Tenant.switch params['tenant'] do
        # Checking recognized storages
        storages_attributes = {}
        if parsed[:destination].to_a.length == 1
          # If there's only one destination, entry quantity is the destination quantity in hectoliters
          storages_attributes["0"] = {"storage_id" => parsed[:destination][0][:key],"quantity_value" =>
          unit_to_hectoliter(parsed[:parameters]['quantity']['rate'],parsed[:parameters]['quantity']['unit']),
          "quantity_unit" => "hectoliter"}
        else
          parsed[:destination].to_a.each_with_index do |cuve, index|
            storages_attributes[index] = {"storage_id"=> cuve[:key], "quantity_value"=>cuve[:quantity], "quantity_unit" => "hectoliter"}
          end
        end
        # Checking recognized targets & crop_groups
        targets_attributes = {}
        parsed[:targets].to_a.each_with_index do |target, index|
          targets_attributes[index] = {"plant_id" => target[:key], "harvest_percentage_received" => target[:area].to_s}
        end
        parsed[:crop_groups].to_a.each_with_index do |cropgroup, index|
          CropGroup.available_crops(cropgroup[:key], "is plant").each_with_index do |crop, index2|
              targets_attributes["#{index}#{index2}"] = {"plant_id" => crop[:id], "harvest_percentage_received" => cropgroup[:area].to_s}
          end
        end
        # Checking secondary parameters
        date = params[:parsed][:date]
        # If unit is "ton" multiply quantity by 1000
        if parsed[:parameters]['quantity']['unit'] == "t"
          parsed[:parameters]['quantity']['rate'] *= 1000
        end
        # Extract quantity per target in correlation with area harvested
        total_area = targets_attributes.values.inject(0) {|sum, tar| sum + Plant.find_by(id: tar["plant_id"])&.net_surface_area&.to_f* tar["harvest_percentage_received"].to_f/100  }
        targets_attributes.values.each do |tar|
          tar["quantity"] = {"value" => parsed[:parameters]['quantity']['rate']* Plant.find_by(id: tar["plant_id"])&.net_surface_area&.to_f* tar["harvest_percentage_received"].to_f/(100 * total_area),
                            "unit" => ("kilogram" if ["kg","t"].include?(parsed[:parameters]['quantity']['unit' ])) || "hectoliter" }
        end

        analysis = Analysis.create!({
         nature: "vine_harvesting_analysis",
         analysed_at: Time.zone.parse(date),
         sampled_at: Time.zone.parse(date),
         items_attributes: create_analysis_attributes(parsed)}
        )

        harvest_dic = {
          received_at: Time.zone.parse(date),
          storages_attributes: storages_attributes,
          quantity_value: parsed[:parameters]['quantity']['rate'].to_s,
          quantity_unit: ("kilogram" if ["kg","t"].include?(parsed[:parameters]['quantity']['unit' ])) || "hectoliter",
          analysis: analysis,
          plants_attributes: targets_attributes}

        incoming_harvest_dic = create_incoming_harvest_attr(harvest_dic, parsed)
        incomingHarvest = WineIncomingHarvest.create!(incoming_harvest_dic)
        return {"link" => "\\backend\\wine_incoming_harvests\\"+incomingHarvest['id'].to_s}
      end
    end
  end
end
