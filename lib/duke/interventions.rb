module Duke
  class Interventions < Duke::Utils::InterventionUtils

    def handle_parse_sentence(params)
      # First parsing inside interventions
      Ekylibre::Tenant.switch params['tenant'] do
        procedure = params[:procedure]
        # Check for | delimiter inside procedure type, if exists, it means it's Ekyviti and we have choice between vegetal & viti procedure
        unless procedure.scan(/[|]/).empty?
          # If there's no vegetal farming for the specific teant, we take viti procedure, otherwise we ask the user
          if Activity.availables.any? {|act| act[:family] != :vine_farming}
            what_next, sentence, optional = disambiguate_procedure(procedure, "|")
            return {:parsed => params[:user_input], :redirect => what_next, :sentence => sentence, :optional => optional}
          else 
            procedure = procedure.split(/[|]/)[0]
          end 
        end 
        # Check for ~ delimiter inside procedure type, if exists, it means there's an amibuity in the user asking (ex : weeding -> (steam ?, gaz ?)) and we ask him
        unless procedure.scan(/[~]/).empty?
          what_next, sentence, optional = disambiguate_procedure(procedure, "~")
          return {:parsed => params[:user_input], :redirect => what_next, :sentence => sentence, :optional => optional}
        end 
        # If the procedure doesn't match anything -> We cancel the capture
        return if Procedo::Procedure.find(procedure).nil?
        # Temporary : Duke only supports vine_farming & plant_farming procedures
        unless (Procedo::Procedure.find(procedure).activity_families & [:vine_farming, :plant_farming]).any?
          return {:redirect => "non_supported_proc"}
        end 
        # Finding when it happened and how long it lasted, + getting cleaned user_input
        user_input = clear_string(params[:user_input])
        date, duration = extract_date_and_duration(user_input)
        # Removing word that matched procedure type
        user_input = user_input.gsub(params[:procedure_word], "")
        parsed = {:inputs => [],
                  :workers => [],
                  :equipments => [],
                  :procedure => procedure,
                  :duration => duration,
                  :date => date,
                  :user_input => params[:user_input],
                  :retry => 0}
        # Define the type of targets that needs to be checked, given the procedure type
        tag_specific_targets(parsed)
        # Then extract every possible user_specifics elements form the sentence (here : inputs, workers, equipments, targets)
        extract_user_specifics(user_input, parsed, 0.89)
        # Look for a specified rate for the input, or attribute nil
        add_input_rate(user_input, parsed[:inputs], parsed[:procedure])
        # Loof for ambiguities in what has been parsed
        parsed[:ambiguities] = find_ambiguity(parsed, user_input, 0.02)
        # Then redirect to what needs to be added, or to save-state
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :sentence => sentence, :redirect => what_next, :optional => optional, :modifiable => modification_candidates(parsed) }
      end
    end

    def handle_modify_specific(params)
      # Function called when user wants to modify one of his specific entities
      parsed = params[:parsed]
      # which_specific corresponds to the type of element to be modified (inputs, workers..)
      which_specific = params[:specific].to_sym
      Ekylibre::Tenant.switch params['tenant'] do
        user_input = clear_string(params[:user_input])
        new_parsed = {which_specific => [],
                      :procedure => parsed[:procedure],
                      :date => parsed[:date],
                      :user_input => user_input}
        #Define the type of targets to check if we are modifying targets
        if which_specific == :targets
          tag_specific_targets(new_parsed)
        end 
        # Extract entites from new user-utterance
        extract_user_specifics(user_input, new_parsed, 0.82)
        # In case we are modifying inputs, we need to add input-rates
        if which_specific == :inputs 
          add_input_rate(user_input, new_parsed[:inputs], parsed[:procedure])
        end 
        # When modifying targets, modifying entries in parsed dic with correct target parameters linked to this procedure
        if which_specific == :targets
          parsed[:crop_groups] = new_parsed[:crop_groups]
          parsed[Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :target}.name] =  new_parsed[Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :target}.name]
        else
          # Otherwise, which_specific previously parsed with new value
          parsed[which_specific] = new_parsed[which_specific]
        end 
        parsed[:user_input] += " -  #{params[:user_input]}"
        parsed[:ambiguities] = find_ambiguity(new_parsed, user_input, 0.02)
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
      end
    end

    def handle_modify_temporality(params)
      # Function called when user wants to modify his intervention's temporality
      parsed = params[:parsed]
      user_input = clear_string(params[:user_input])
      date, duration = extract_date_and_duration(user_input)
      # Choose date & duration between previous value & new one
      parsed[:date] = choose_date(date, parsed[:date])
      parsed[:duration] = choose_duration(duration, parsed[:duration])
      parsed[:user_input] += " - #{params[:user_input]}"
      parsed[:ambiguities] = []
      what_next, sentence, optional = redirect(parsed)
      return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
    end

    def handle_parse_input_quantity(params)
      # function called to parse a number corresponding to the number of "unit_name" of an input, when no rate was specified
      parsed = params[:parsed]
      value = extract_number_parameter(params[:quantity], params[:user_input])
      # If there's no number, redirect
      if value.nil?
        parsed[:retry] += 1
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
      end
      # Otherwise add value for the given input (we get it via it's index in parsed[:inputs])
      parsed[:inputs][params[:optional]][:rate][:value] = value
      parsed[:user_input] += " - #{params[:user_input]}"
      parsed[:retry] = 0
      what_next, sentence, optional = redirect(parsed)
      return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
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
        # If the type of ambiguation is an input, make sure quantity handlers are concording with new input, otherwise remove rate infos
        if ambType.to_sym == :inputs 
          if ([:net_mass, :mass_area_density].include? ambHash[:rate][:unit].to_sym and Matter.where("id = #{ambHash[:key]}").first&.net_mass.to_f == 0) || ([:net_volume, :volume_area_density].include? ambHash[:rate][:unit].to_sym and Matter.where("id = #{ambHash[:key]}").first&.net_volume.fo_f == 0)
            ambHash[:rate][:unit] = :population 
            ambHash[:rate][:value] = nil 
          end 
        end 
      rescue
        # If user clicked on "tous" button, we add every value that was suggested
        if params[:user_input] == "Tous"
          params[:optional].each_with_index do |ambiguate, index|
            # Last two values are useless or already in, so we append every other ones
            unless [1,2].include?(params[:optional].length - index)
              hashClone = ambHash.clone()
              hashClone[:name] = ambiguate[:name].to_s
              hashClone[:key] = ambiguate[:key].to_s
              ambArray.push(hashClone)
              # If ambiguation type is an input, and we add multiple, we ask how much quantity for each new input
              if ambType.to_sym == :inputs 
                hashClone[:rate][:unit] = :population 
                hashClone[:rate][:value] = nil 
              end 
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

    def handle_save_intervention(params)
      # Function that's called when user press "save" button
      # Saves intervention & returns the link to it, to interface-redirect user
      I18n.locale = :fra
      Ekylibre::Tenant.switch params['tenant'] do
        # If procedure type can handle tools 
        tools_attributes = []
        unless Procedo::Procedure.find(params[:parsed][:procedure]).parameters_of_type(:tool).empty?
          # For each tool, append it with the correct reference name if exists, or with the first reference-name from proc
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
        # If procedure type can handle workers, save each worker with first reference name from proc
        doers_attributes = []
        unless Procedo::Procedure.find(params[:parsed][:procedure]).parameters_of_type(:doer).empty?
          params[:parsed][:workers].to_a.each do |worker|
            doers_attributes.push({"reference_name" => Procedo::Procedure.find(params[:parsed][:procedure]).parameters_of_type(:doer)[0].name, "product_id" => worker[:key]})
          end
        end 
        # If procedure type can handle inputs
        inputs_attributes = []
        unless Procedo::Procedure.find(params[:parsed][:procedure]).parameters_of_type(:input).empty?
          params[:parsed][:inputs].to_a.each do |input|
            # For each input, save it with the reference name from it's type of input which was detected in the proc
            inputs_attributes.push({"reference_name" => Procedo::Procedure.find(params[:parsed][:procedure]).parameters_of_type(:input).find {|inp| Matter.where("id = #{input[:key]}").first.of_expression(inp.filter)}.name,
                                    "product_id" => input[:key],
                                    "quantity_value" => input[:rate][:value].to_f,
                                    "quantity_population" => input[:rate][:value].to_f,
                                    "quantity_handler" => input[:rate][:unit]})
          end
        end
        # If procedure type can handle targets
        targets_attributes = []
        unless Procedo::Procedure.find(params[:parsed][:procedure]).parameters.find {|param| param.type == :target}.nil?
          # Add each target 
          params[:parsed][Procedo::Procedure.find(params[:parsed][:procedure]).parameters.find {|param| param.type == :target}.name].to_a.each do |target|
            targets_attributes.push({"reference_name" => Procedo::Procedure.find(params[:parsed][:procedure]).parameters.find {|param| param.type == :target}.name, "product_id" => target[:key]})
          end 
          # Add each target from specified cropgroups
          params[:parsed][:crop_groups].to_a.each do |cropgroup|
            CropGroup.available_crops(cropgroup[:key], "is plant").each do |crop|
              targets_attributes.push({"reference_name" => Procedo::Procedure.find(params[:parsed][:procedure]).parameters.find {|param| param.type == :target}.name, "product_id" => crop[:id]})
            end
          end
        end 
        duration = params[:parsed][:duration].to_i
        date = params[:parsed][:date]
        # Finally save intervention
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
