module Duke
  class Interventions < Duke::Utils::InterventionUtils

    def handle_parse_sentence(params)
      Ekylibre::Tenant.switch params['tenant'] do
        procedure = params['procedure']
        unless procedure.scan(/[|]/).empty?
          if Activity.availables.any? {|act| act[:family] != :vine_farming}
            what_next, sentence, optional = disambiguate_procedure(procedure)
            return {:parsed => params[:user_input], :redirect => what_next, :sentence => sentence, :optional => optional}
          else 
            procedure = procedure.split(/[|]/)[0]
          end 
        end 
        return if Procedo::Procedure.find(procedure).nil?
        unless (Procedo::Procedure.find(procedure).activity_families & [:vine_farming, :plant_farming]).any?
          return {:redirect => "non_supported_proc"}
        end 
        equipments, workers, inputs = [], [], []
        # Finding when it happened and how long it lasted, + getting cleaned user_input
        date, duration, user_input = extract_date_and_duration(clear_string(params[:user_input]))
        parsed = {:inputs => inputs,
                  :workers => workers,
                  :equipments => equipments,
                  :procedure => procedure,
                  :duration => duration,
                  :date => date,
                  :user_input => params[:user_input],
                  :retry => 0}
        tag_specific_targets(parsed)
        extract_user_specifics(user_input, parsed, 0.89)
        add_input_rate(user_input, parsed[:inputs])
        parsed[:ambiguities] = find_ambiguity(parsed, user_input, 0.02)
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :sentence => sentence, :redirect => what_next, :optional => optional, :modifiable => modification_candidates(parsed) }
      end
    end

    def handle_parse_disambiguation(params)
      # Handle disambiguation when users returns a choice.
      # Last two elements from an Ambiguate Item are respectively : -2: Element that matches and his key, -1: InSentenceName and what we matched in user sentence
      parsed = params[:parsed]
      # Find the parsed element that we're gonna modify
      ambElement = params[:optional][-2]
      # Find the type of element (:input, :plant ..) and the corresponding array from the previously parsed items
      ambType, ambArray = parsed.find { |key, value| value.is_a?(Array) and value.any? { |subhash| subhash[:name] == ambElement[:name]}}
      # Find the hash in question
      ambHash = ambArray.find {|hash| hash[:name] == ambElement[:name]}
      # If user clicked on the "see more button"
      if ["AddMore", "plus", "voire plus", "encore"].include?(params[:user_input])
        # We recheck for an ambiguity on the specific element that can't be validated by the user, with a bigger level of incertitude
        new_ambiguities = ambiguity_check(ambHash, params[:optional][-1][:name], 0.20, [], find_iterator(ambType.to_sym, parsed))
        # Then we remove elements that have already been suggested to the user (we leave last two which will be used when we come back here)
        new_ambiguities[0].reject! {|item| (parsed[:ambiguities][0][0..-3] & new_ambiguities[0]).include? (item)}
        # If more than 7 items remains, drop some
        new_ambiguities[0] = new_ambiguities[0].drop((new_ambiguities[0].length - 9 if new_ambiguities[0].length - 9 > 0 ) || 0)
        parsed[:ambiguities] = new_ambiguities 
        return { :parsed => parsed, :redirect => "see_more_ambiguity", :optional => parsed[:ambiguities][0]}
      end 
      begin
        # If the user_input can be turned to an hash -> user clicked on a value, we replace the name & key from the previously chosen one
        chosen_one = eval(params[:user_input])
        ambHash[:name] = chosen_one["name"]
        ambHash[:key] = chosen_one["key"]
      rescue
        if params[:user_input] == "Tous"
          params[:optional].each_with_index do |ambiguate, index|
            # Last two values are useless or already in, so we append every other ones
            unless [1,2].include?(params[:optional].length - index)
              hashClone = ambHash.clone()
              hashClone[:name] = ambiguate[:name].to_s
              hashClone[:key] = ambiguate[:key].to_s
              ambArray.push(hashClone)
            end
          end
        elsif params[:user_input] == "Aucun"
          # On None -> We delete the previously chosen value from what was parsed
          ambArray.delete(ambHash)
        end
      ensure
        # This ambiguity has been take care of, we remove it from parsed[:ambiguities]
        parsed[:ambiguities].shift
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
      end
    end

    def handle_modify_target(params)
      parsed = params[:parsed]
      Ekylibre::Tenant.switch params['tenant'] do
        crop_groups = []
        user_input = clear_string(params[:user_input])
        new_parsed = {:procedure => parsed[:procedure],
                      :duration => parsed[:duration],
                      :date => parsed[:date],
                      :user_input => user_input}
        tag_specific_targets(new_parsed)
        extract_user_specifics(user_input, new_parsed, 0.82)
        parsed[:crop_groups] = new_parsed[:crop_groups]
        parsed[Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :target}.name] =  new_parsed[Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :target}.name]
        parsed[:user_input] += " - (Cultures) #{params[:user_input]}"
        parsed[:ambiguities] = find_ambiguity(new_parsed, user_input, 0.02)
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
      end
    end

    def handle_modify_worker(params)
      parsed = params[:parsed]
      Ekylibre::Tenant.switch params['tenant'] do
        workers = []
        user_input = clear_string(params[:user_input])
        new_parsed = {:workers => workers,
                      :procedure => parsed[:procedure],
                      :duration => parsed[:duration],
                      :date => parsed[:date],
                      :user_input => user_input}
        extract_user_specifics(user_input, new_parsed, 0.82)
        parsed[:workers] = new_parsed[:workers]
        parsed[:user_input] += " - (Travailleurs) #{params[:user_input]}"
        parsed[:ambiguities] = find_ambiguity(new_parsed, user_input, 0.02)
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
      end
    end

    def handle_modify_input(params)
      parsed = params[:parsed]
      Ekylibre::Tenant.switch params['tenant'] do
        inputs = []
        user_input = clear_string(params[:user_input])
        new_parsed = {:inputs => inputs,
                      :procedure => parsed[:procedure],
                      :duration => parsed[:duration],
                      :date => parsed[:date],
                      :user_input => user_input}
        extract_user_specifics(user_input, new_parsed, 0.82)
        add_input_rate(user_input, new_parsed[:inputs])
        parsed[:inputs] = new_parsed[:inputs]
        parsed[:user_input] += " - (Intrants) #{params[:user_input]}"
        parsed[:ambiguities] = find_ambiguity(new_parsed, user_input, 0.02)
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
      end
    end

    def handle_modify_temporality(params)
      parsed = params[:parsed]
      date, duration, user_input = extract_date_and_duration(clear_string(params[:user_input]))
      parsed[:date] = choose_date(date, parsed[:date])
      parsed[:duration] = choose_duration(duration, parsed[:duration])
      parsed[:user_input] += " - (Temporalité) #{params[:user_input]}"
      parsed[:ambiguities] = []
      what_next, sentence, optional = redirect(parsed)
      return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
    end

    def handle_modify_equipment(params)
      parsed = params[:parsed]
      Ekylibre::Tenant.switch params['tenant'] do
        equipments = []
        user_input = clear_string(params[:user_input])
        new_parsed = {:equipments => equipments,
                      :procedure => parsed[:procedure],
                      :duration => parsed[:duration],
                      :date => parsed[:date],
                      :user_input => user_input}
        extract_user_specifics(user_input, new_parsed, 0.82)
        parsed[:equipments] = new_parsed[:equipments]
        parsed[:user_input] += " - (Equipement) #{params[:user_input]}"
        parsed[:ambiguities] = find_ambiguity(new_parsed, user_input, 0.02)
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
      end
    end

    def handle_parse_input_quantity(params)
      parsed = params[:parsed]
      value = extract_number_parameter(params[:quantity], params[:user_input])
      if value.nil?
        parsed[:retry] += 1
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
      end
      parsed[:inputs][params[:optional]][:rate][:value] = value
      parsed[:user_input] += " - (Quantité) #{params[:user_input]}"
      parsed[:retry] = 0
      what_next, sentence, optional = redirect(parsed)
      return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
    end


    def handle_save_intervention(params)
      I18n.locale = :fra
      Ekylibre::Tenant.switch params['tenant'] do
        tools_attributes = []
        unless Procedo::Procedure.find(params[:parsed][:procedure]).parameters_of_type(:tool).empty?
          params[:parsed][:equipments].to_a.each do |tool|
            reference_name = Procedo::Procedure.find(params[:parsed][:procedure]).parameters_of_type(:tool)[0].name
            Procedo::Procedure.find(params[:parsed][:procedure]).parameters.find_all {|param| param.type == :tool}.each do |tool_type|
              if Equipment.of_expression(tool_type.filter).include? Equipment.where("id = #{tool[:key]}")[0]
                reference_name = tool_type.name
                break 
              end 
            end 
            tools_attributes.push({"reference_name" => reference_name, 'product_id' => tool[:key]})
          end
        end
        doers_attributes = []
        params[:parsed][:workers].to_a.each do |worker|
          doers_attributes.push({"reference_name" => Procedo::Procedure.find(params[:parsed][:procedure]).parameters_of_type(:doer)[0].name, "product_id" => worker[:key]})
        end
        inputs_attributes = []
        unless Procedo::Procedure.find(params[:parsed][:procedure]).parameters_of_type(:input).empty?
          params[:parsed][:inputs].to_a.each do |input|
            inputs_attributes.push({"reference_name" => Procedo::Procedure.find(params[:parsed][:procedure]).parameters_of_type(:input)[0].name,
                                               "product_id" => input[:key],
                                               "quantity_value" => input[:rate][:value].to_f*input[:rate][:factor],
                                               "quantity_population" => input[:rate][:value].to_f*input[:rate][:factor],
                                               "quantity_handler" => input[:rate][:unit]})
          end
        end
        unless Procedo::Procedure.find(params[:parsed][:procedure]).parameters.find {|param| param.type == :target}.nil?
          targets_attributes = []
          params[:parsed][Procedo::Procedure.find(params[:parsed][:procedure]).parameters.find {|param| param.type == :target}.name].to_a.each do |target|
            targets_attributes.push({"reference_name" => Procedo::Procedure.find(params[:parsed][:procedure]).parameters.find {|param| param.type == :target}.name, "product_id" => target[:key]})
          end 
          params[:parsed][:crop_groups].to_a.each do |cropgroup|
            CropGroup.available_crops(cropgroup[:key], "is plant").each do |crop|
              targets_attributes.push({"reference_name" => Procedo::Procedure.find(params[:parsed][:procedure]).parameters.find {|param| param.type == :target}.name, "product_id" => crop[:id]})
            end
          end
        end 
        duration = params[:parsed][:duration].to_i
        date = params[:parsed][:date]

        intervention = Intervention.create!(procedure_name: params[:parsed][:procedure],
                                            description: 'Duke : ' << params[:parsed][:user_input],
                                            state: 'done',
                                            number: '50',
                                            nature: 'record',
                                            tools_attributes: tools_attributes,
                                            doers_attributes: doers_attributes,
                                            targets_attributes: targets_attributes,
                                            inputs_attributes: inputs_attributes,
                                            working_periods_attributes:   [ { "started_at": Time.zone.parse(date) , "stopped_at": Time.zone.parse(date) + duration.minutes}])
        return {"link" => "\\backend\\interventions\\"+intervention['id'].to_s}
      end
    end
  end
end
