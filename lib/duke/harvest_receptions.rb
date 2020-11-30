module Duke
  class HarvestReceptions < Duke::Utils::HarvestReceptionUtils

    def handle_parse_sentence(params)
      # First parsing inside harvest receptions
      Ekylibre::Tenant.switch params['tenant'] do
        # Extract date and parameters
        user_input = clear_string(params[:user_input])
        date = extract_date(user_input)
        parameters = extract_reception_parameters(user_input)
        parsed = {:plant => [],
                  :crop_groups => [],
                  :destination => [],
                  :parameters => parameters,
                  :date => date,
                  :user_input => params[:user_input],
                  :retry => 0}
        # Then extract user_specifics (plant, crop_group & destination), and add plant_area %
        extract_user_specifics(user_input, parsed, 0.89)
        extract_plant_area(user_input, parsed[:plant], parsed[:crop_groups])
        parsed[:ambiguities] = find_ambiguity(parsed, user_input, 0.02)
        # Find if crucials parameters haven't been given, to ask again to the user
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
      end
    end

    def handle_parse_parameter(params)
      # Parse parameters when modifying it
      parsed = params[:parsed]
      # Parameter is the type of parameter to be checked
      parameter = params[:parameter]
      # Look for its value (params[params[:parameter]])
      value = extract_number_parameter(params[parameter], params[:user_input])
      if value.nil?
        # If we couldn't find one, we cancel the functionnality
        parsed[:retry] += 1
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
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
      return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
    end

    def handle_modify_quantity_tav(params)
      # Modify tavp &/or quantity
      parsed = params[:parsed]
      new_params = {}
      user_input = clear_string(params[:user_input])
      new_params = extract_quantity(user_input, new_params)
      new_params = extract_conflicting_degrees(user_input, new_params)
      new_params = extract_tav(user_input, new_params)
      # Append new value if not null
      unless new_params['quantity'].nil?
        parsed[:parameters]['quantity'] = new_params['quantity']
      end
      # Same for TAVP
      unless new_params['tav'].nil?
        parsed[:parameters]['tav'] = new_params['tav']
      end
      parsed[:user_input] += " - #{params[:user_input]}"
      what_next, sentence, optional = redirect(parsed)
      return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
    end

    def handle_modify_date(params)
      # Modify date
      parsed = params[:parsed]
      user_input = clear_string(params[:user_input])
      date = extract_date(user_input)
      parsed[:date] = date
      parsed[:user_input] += " - #{params[:user_input]}"
      what_next, sentence, optional = redirect(parsed)
      return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
    end

    def handle_parse_destination_quantity(params)
      # Add quantity to a specific destination afer being asked to the user
      parsed = params[:parsed]
      parameter = params[:parameter]
      value = extract_number_parameter(params[parameter], params[:user_input])
      if value.nil?
        parsed[:retry] += 1
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
      end
      if parameter == "destination"
        parsed[:destination][params[:optional]][:quantity] = value
      else
        parsed[:press][params[:optional]][:quantity] = value
      end
      parsed[:user_input] += " - (Quantité) #{params[:user_input]}"
      parsed[:retry] = 0
      what_next, sentence, optional = redirect(parsed)
      return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
    end

    def handle_parse_targets(params)
      # Adding targets 
      parsed = params[:parsed]
      Ekylibre::Tenant.switch params['tenant'] do
        user_input = clear_string(params[:user_input])
        new_parsed = {:plant => [],
                      :crop_groups => [],
                      :date => parsed[:date]}
        extract_user_specifics(user_input, new_parsed, 0.82)
        extract_plant_area(user_input, new_parsed[:plant], new_parsed[:crop_groups])
        # If there's no new Target/Crop_group, But a percentage, it's the new area % foreach previous target
        if new_parsed[:crop_groups].empty? and new_parsed[:plant].empty?
          pct_regex = user_input.match(/(\d{1,2}) *(%|pour( )?cent(s)?)/)
          if pct_regex
            parsed[:crop_groups].to_a.each { |crop_group| crop_group[:area] = pct_regex[1]}
            parsed[:plant].to_a.each { |target| target[:area] = pct_regex[1]}
          end
        else
          parsed[:plant] = new_parsed[:plant]
          parsed[:crop_groups] = new_parsed[:crop_groups]
          parsed[:ambiguities] = find_ambiguity(new_parsed, user_input, 0.02)
        end
      end
      parsed[:user_input] += " - #{params[:user_input]}"
      what_next, sentence, optional = redirect(parsed)
      if what_next == params[:current_asking]
        parsed[:retry] += 1
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
      end
      parsed[:retry] = 0
      return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
    end

    def handle_parse_destination(params)
      # Adding destination
      parsed = params[:parsed]
      Ekylibre::Tenant.switch params['tenant'] do
        user_input = clear_string(params[:user_input]).gsub("que","cuve")
        new_parsed = {:destination => [],
                      :date => parsed[:date]}
        extract_user_specifics(user_input, new_parsed, 0.82)
        parsed[:destination] = new_parsed[:destination]
        parsed[:ambiguities] = find_ambiguity(new_parsed, user_input, 0.02)
      end
      parsed[:user_input] += " - #{params[:user_input]}"
      what_next, sentence, optional = redirect(parsed)
      if what_next == params[:current_asking] and optional == params[:optional]
        parsed[:retry] += 1
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
      end
      parsed[:retry] = 0
      return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
    end

    def handle_add_other(params)
      # Used to add none and redirect to save interface
      what_next, sentence, optional = redirect(parsed)
      return  { :parsed => params[:parsed], :redirect => what_next, :sentence => sentence, :optional => optional}
    end

    def handle_parse_disambiguation(params)
      # Handle disambiguation when users returns a choice.
      parsed = params[:parsed]
      # Retrieving id of element we'll modify
      current_id = params[:optional].first['description']['id']
      # Find the type of element (:input, :plant ..) and the corresponding array from the previously parsed items, then find the correct hash
      current_type, current_array = parsed.find { |key, value| value.is_a?(Array) and value.any? { |subhash| subhash[:key] == current_id}}
      current_hash = current_array.find {|hash| hash[:key] == current_id}
      if ["SeeMore", "voire plus", "voir plus", "plus"].include? params[:user_input]
        current_level = params[:optional].first[:description][:level]
        what_matched = params[:optional].first[:description][:match]
        # We recheck for an ambiguity on the specific element that can't be validated by the user, with a bigger level of incertitude
        new_ambiguities = ambiguity_check(current_hash, what_matched, current_level + 0.25, [], find_iterator(current_type.to_sym, parsed), current_level)
        # If we have no new ambiguities, remove the values that was added, alert the user, and redirect him to next step 
        if new_ambiguities.first.nil?
          current_array.delete(current_hash)
          parsed[:ambiguities].shift
          what_next, sentence, optional = redirect(parsed)
          return {:parsed => parsed, :alert => "no_more_ambiguity", :redirect => what_next, :optional => optional, :sentence => sentence}
        end 
        parsed[:ambiguities][0]= new_ambiguities.first
        return { :parsed => parsed, :redirect => "ask_ambiguity", :optional => parsed[:ambiguities].first}
      end 
      begin
        chosen_one = eval(params[:user_input])
        current_hash[:name] = chosen_one[:name]
        current_hash[:key] = chosen_one[:key]
      rescue
        if params[:user_input] == "Tous"
          current_array.delete(current_hash)
          params[:optional].first['options'].each_with_index do |ambiguate, index|
            begin 
              hashClone = current_hash.clone()
              ambiguate_values = eval(ambiguate[:value][:input][:text])
              hashClone[:name] = ambiguate_values[:name]
              hashClone[:key] = ambiguate_values[:key]
              current_array.push(hashClone)
            end 
          end
        elsif params[:user_input] == "Aucun"
          # On None -> We delete the previously chosen value from what was parsed
          current_array.delete(current_hash)
        end
      ensure
        parsed[:ambiguities].shift
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
      end
    end

    def handle_add_analysis(params)
      # Add analysis elements, and concatenate with previous ones
      user_input = clear_string(params[:user_input])
      new_parameters = extract_reception_parameters(user_input)
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
      return  { :parsed => params[:parsed], :redirect => what_next, :sentence => sentence, :optional => optional}
    end

    def handle_add_pressing(params)
      # Add a press
      parsed = params[:parsed]
      user_input = clear_string(params[:user_input])
      Ekylibre::Tenant.switch params['tenant'] do
        new_parsed = {:press => [],
                      :date => parsed[:date]}
        extract_user_specifics(user_input, new_parsed, 0.82)
        parsed[:press] = new_parsed[:press]
        parsed[:ambiguities] = find_ambiguity(new_parsed, user_input, 0.02)
      end
      parsed[:user_input] += " - #{params[:user_input]}"
      what_next, sentence, optional = redirect(parsed)
      if what_next == params[:current_asking] and optional == params[:optional]
        parsed[:retry] += 1
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
      end
      parsed[:retry] = 0
      return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
    end

    def handle_add_complementary(params)
      # Add complementary parameters
      if params[:parsed][:parameters][:complementary].nil?
        complementary = {}
      else
        complementary = params[:parsed][:parameters][:complementary]
      end
      complementary[params[:parameter]] = params[:user_input]
      params[:parsed][:parameters][:complementary] = complementary
      # Find if crucials parameters haven't been given, to ask again to the user
      what_next, sentence, optional = redirect(params[:parsed])
      return  { :parsed => params[:parsed], :redirect => what_next, :sentence => sentence, :optional => optional}
    end

    def handle_save_harvest_reception(params)
      # Finally save the harvest reception
      I18n.locale = :fra
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
        parsed[:plant].to_a.each_with_index do |target, index|
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
        # total_area = targets_attributes.values.inject(0) {|sum, tar| sum + Plant.find_by(id: tar["plant_id"])&.net_surface_area&.to_f* tar["harvest_percentage_received"].to_f/100  }
        # targets_attributes.values.each do |tar|
        #  tar["quantity"] = {"value" => parsed[:parameters]['quantity']['rate']* Plant.find_by(id: tar["plant_id"])&.net_surface_area&.to_f* tar["harvest_percentage_received"].to_f/(100 * total_area),
        #                   "unit" => ("kilogram" if ["kg","t"].include?(parsed[:parameters]['quantity']['unit' ])) || "hectoliter" }
        # end

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
