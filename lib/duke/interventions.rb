module Duke
  class Interventions < Duke::Utils::InterventionUtils

    def handle_parse_sentence(params)
      # First parsing inside interventions
      # params procedure      -> Procedure_name 
      #        user_input     -> Sentence inputed by the user 
      #        procedure_word -> Word in user_input that matched a procedure
      procedure = params[:procedure]
      return if procedure.nil?
      # Check for | delimiter inside procedure type, if exists, it means it's Ekyviti and we have choice between vegetal & viti procedure
      unless procedure.scan(/[|]/).empty?
        # If there's no vegetal farming for the specific teant, we take viti procedure, otherwise we ask the user
        if Activity.availables.any? {|act| act[:family] != :vine_farming}
          what_next, sentence, optional = disambiguate_procedure(procedure, "|")
          return {parsed: params[:user_input], redirect: what_next, sentence: sentence, optional: optional}
        else 
          procedure = procedure.split(/[|]/).first
        end 
      end 
      # Check for ~ delimiter inside procedure type, if exists, it means there's an amibuity in the user asking (ex : weeding -> (steam ?, gaz ?)) and we ask him
      unless procedure.scan(/[~]/).empty?
        what_next, sentence, optional = disambiguate_procedure(procedure, "~")
        return {parsed: params[:user_input], redirect: what_next, sentence: sentence, optional: optional}
      end 
      # If the procedure doesn't match anything -> We cancel the capture
      return if Procedo::Procedure.find(procedure).nil?
      # Temporary : Duke only supports vine_farming & plant_farming procedures
      unless (Procedo::Procedure.find(procedure).activity_families & [:vine_farming, :plant_farming]).any?
        return {redirect: "non_supported_proc"}
      end 
      # getting cleaned user_input
      user_input = clear_string(params[:user_input].gsub(params[:procedure_word], ""))
      # Finding when it happened and how long it lasted
      date, duration = extract_date_and_duration(user_input)
      parsed = {inputs: [],
                workers: [],
                equipments: [],
                procedure: procedure,
                duration: duration,
                date: date,
                user_input: params[:user_input],
                retry: 0}
      # Define the type of targets that needs to be checked, given the procedure type
      tag_specific_targets(parsed)
      # Then extract every possible user_specifics elements form the sentence (here : inputs, workers, equipments, targets)
      extract_user_specifics(user_input, parsed, 0.89)
      # Look for a specified rate for the input, or attribute nil
      add_input_rate(user_input, parsed[:inputs], parsed[:procedure])
      # extract_readings 
      extract_intervention_readings(user_input, parsed)
      # Loof for ambiguities in what has been parsed
      parsed[:ambiguities] = find_ambiguity(parsed, user_input, 0.02)
      targets_from_cz(parsed)
      # Then redirect to what needs to be added, or to save-state
      what_next, sentence, optional = redirect(parsed)
      return  { parsed: parsed, sentence: sentence, redirect: what_next, optional: optional, modifiable: modification_candidates(parsed) }
    end

    def handle_modify_specific(params)
      # Function called when user wants to modify one of his specific entities
      # params parsed     -> previously parsed items 
      #        user_input -> Sentence inputed by the user 
      #        specific   -> Type of specific to be parsed (target, input, doer ..)
      parsed = params[:parsed]
      # which_specific corresponds to the type of element to be modified (inputs, workers..)
      which_specific = params[:specific].to_sym
      user_input = clear_string(params[:user_input])
      new_parsed = {which_specific => [],
                    procedure: parsed[:procedure],
                    date: parsed[:date],
                    user_input: user_input}
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
        if Procedo::Procedure.find(parsed[:procedure]).activity_families.include? :vine_farming
          parsed[Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :target}.name] =  new_parsed[Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :target}.name]
        else 
          parsed[:cultivablezones] = new_parsed[:cultivablezones]
          parsed[:activity_variety] = new_parsed[:activity_variety]
          targets_from_cz(parsed)
        end 
      else
        # Otherwise, which_specific previously parsed with new value
        parsed[which_specific] = new_parsed[which_specific]
      end 
      parsed[:user_input] += " -  #{params[:user_input]}"
      parsed[:ambiguities] = find_ambiguity(new_parsed, user_input, 0.02)
      what_next, sentence, optional = redirect(parsed)
      return  { parsed: parsed, redirect: what_next, sentence: sentence, optional: optional}
    end

    def handle_modify_temporality(params)
      # Function called when user wants to modify his intervention's temporality
      # params : user_input -> Sentence inputed by the user 
      #          parsed     -> What was previously parsed
      parsed = params[:parsed]
      user_input = clear_string(params[:user_input])
      date, duration = extract_date_and_duration(user_input)
      # Choose date & duration between previous value & new one
      parsed[:date] = choose_date(date, parsed[:date])
      parsed[:duration] = choose_duration(duration, parsed[:duration])
      parsed[:user_input] += " - #{params[:user_input]}"
      parsed[:ambiguities] = []
      what_next, sentence, optional = redirect(parsed)
      return  { parsed: parsed, redirect: what_next, sentence: sentence, optional: optional}
    end

    def handle_parse_input_quantity(params)
      # function called to parse a number corresponding to the number of "unit_name" of an input, when no rate was specified
      # params : user_input -> Sentence inputed by the user 
      #          parsed     -> What was previously parsed 
      #          quantity   -> Number parsed by IBM 
      #          optional   -> Index of input that needs modification inside parsed[:inputs], Integer
      parsed = params[:parsed]
      value = extract_number_parameter(params[:quantity], params[:user_input])
      # If there's no number, redirect
      if value.nil?
        parsed[:retry] += 1
        what_next, sentence, optional = redirect(parsed)
        return  { parsed: parsed, redirect: what_next, sentence: sentence, optional: optional}
      end
      # Otherwise add value for the given input (we get it via it's index in parsed[:inputs])
      parsed[:inputs][params[:optional]][:rate][:value] = value
      parsed[:user_input] += " - #{params[:user_input]}"
      parsed[:retry] = 0
      what_next, sentence, optional = redirect(parsed)
      return  { parsed: parsed, redirect: what_next, sentence: sentence, optional: optional}
    end

    def handle_parse_which_target(params) 
      # Function called to find which targets were selected by the user when multiple choice is available for vegetal procedures
      # params : user_input -> Sentence inputed by the user 
      #          parsed     -> What was previously parsed 
      parsed = params[:parsed]
      tar_type = Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :target}.name
      # If response type matches a multiple click response
      if params[:user_input].match(/^(\d{1,5}[|])*$/)
        # Creating a list with all integers corresponding to targets.ids chosen by the user
        every_choices = params[:user_input].split(/[|]/).map{|num| num.to_i}
        # For each target, if the key is in every_choices, we append the key to the targets
        parsed[tar_type] = parsed[tar_type].map{|tar| tar.except!(:potential) if every_choices.include? tar[:key] }.compact
      else 
        # If user didn't validate a click answer, we remove every potential targets
        parsed[tar_type] = []
      end 
      what_next, sentence, optional = redirect(parsed)
      return  { parsed: parsed, redirect: what_next, sentence: sentence, optional: optional}
    end 

    def handle_parse_disambiguation(params)
      # Handle disambiguation when users returns a choice.
      # params : user_input -> Sentence inputed by the user, or data the user clicked
      #          parsed     -> What was previously parsed 
      #          optional   -> The JSON with every ambiguity choices, the title, and the description
      parsed = params[:parsed]
      # Retrieving id of element we'll modify
      current_id = params[:optional].first[:description][:id]
      # Find the type of element (:input, :plant ..) and the corresponding array from the previously parsed items, then find the correct hash
      current_type, current_array = parsed.find { |key, value| value.is_a?(Array) and value.any? { |subhash| subhash[:key] == current_id}}
      current_hash = current_array.find {|hash| hash[:key] == current_id}
      # If user clicked on the "see more button"
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
          return {parsed: parsed, alert: "no_more_ambiguity", redirect: what_next, optional: optional, sentence: sentence}
        end 
        parsed[:ambiguities][0]= new_ambiguities.first
        return { parsed: parsed, redirect: "ask_ambiguity", optional: parsed[:ambiguities].first}
      end 
      begin
        # If the user_input can be turned to an hash -> user clicked on a value, we replace the name & key from the previously chosen one
        chosen_one = eval(params[:user_input])
        current_hash[:name] = chosen_one[:name]
        current_hash[:key] = chosen_one[:key]
        # If the type of ambiguation is an input, make sure quantity handlers are concording with new input, otherwise remove rate infos
        if current_type.to_sym == :inputs 
          if ([:net_mass, :mass_area_density].include? current_hash[:rate][:unit].to_sym and Matter.find_by_id(current_hash[:key])&.net_mass.to_f == 0) || ([:net_volume, :volume_area_density].include? current_hash[:rate][:unit].to_sym and Matter.find_by_id(current_hash[:key])&.net_volume.fo_f == 0)
            current_hash[:rate][:unit] = :population 
            current_hash[:rate][:value] = nil 
          end 
        end 
      rescue
        # If user clicked on "tous" button, we add every value that was suggested
        if params[:user_input] == "Tous"
          current_array.delete(current_hash)
          params[:optional].first[:options].each_with_index do |ambiguate, index|
            begin 
              hashClone = current_hash.clone()
              ambiguate_values = eval(ambiguate[:value][:input][:text])
              hashClone[:name] = ambiguate_values[:name]
              hashClone[:key] = ambiguate_values[:key]
              current_array.push(hashClone)
              # If ambiguation type is an input, and we add multiple, we ask how much quantity for each new input
              if current_type.to_sym == :inputs 
                hashClone[:rate][:unit] = :population 
                hashClone[:rate][:value] = nil 
              end 
            end 
          end
        elsif params[:user_input] == "Aucun"
          # On None -> We delete the previously chosen value from what was parsed
          current_array.delete(current_hash)
        end
      ensure
        # This ambiguity has been take care of, we remove it from parsed[:ambiguities]
        parsed[:ambiguities].shift
        what_next, sentence, optional = redirect(parsed)
        return  { parsed: parsed, redirect: what_next, sentence: sentence, optional: optional}
      end
    end

    def handle_save_intervention(params)
      # Function that's called when user press "save" button
      # Saves intervention & returns the link to it, to interface-redirect user
      # params : parsed     -> What was previously parsed 
      tool_attributes = []
      unless Procedo::Procedure.find(params[:parsed][:procedure]).parameters_of_type(:tool).empty?
        # For each tool, append it with the correct reference name if exists, or with the first reference-name from proc
        params[:parsed][:equipments].to_a.each do |tool|
          reference_name = Procedo::Procedure.find(params[:parsed][:procedure]).parameters_of_type(:tool).first.name
          Procedo::Procedure.find(params[:parsed][:procedure]).parameters.find_all {|param| param.type == :tool}.each do |tool_type|
            if Equipment.of_expression(tool_type.filter).include? Equipment.find_by_id(tool[:key])
              reference_name = tool_type.name
              break 
            end 
          end 
          tool_attributes.push({reference_name: reference_name, product_id: tool[:key]})
        end
      end
      # If procedure type can handle workers, save each worker with first reference name from proc
      doer_attributes = []
      unless Procedo::Procedure.find(params[:parsed][:procedure]).parameters_of_type(:doer).empty?
        params[:parsed][:workers].to_a.each do |worker|
          doer_attributes.push({reference_name: Procedo::Procedure.find(params[:parsed][:procedure]).parameters_of_type(:doer).first.name, product_id: worker[:key]})
        end
      end 
      # If procedure type can handle inputs
      input_attributes = []
      unless Procedo::Procedure.find(params[:parsed][:procedure]).parameters_of_type(:input).empty?
        params[:parsed][:inputs].to_a.each do |input|
          # For each input, save it with the reference name from it's type of input which was detected in the proc
          input_attributes.push({reference_name: Procedo::Procedure.find(params[:parsed][:procedure]).parameters_of_type(:input).find {|inp| Matter.find_by_id(input[:key]).of_expression(inp.filter)}.name,
                                  product_id: input[:key],
                                  quantity_value: input[:rate][:value].to_f,
                                  quantity_population: input[:rate][:value].to_f,
                                  quantity_handler: input[:rate][:unit]})
        end
      end
      # If procedure type can handle targets
      target_attributes = []
      unless Procedo::Procedure.find(params[:parsed][:procedure]).parameters.find {|param| param.type == :target}.nil?
        # Add each target 
        params[:parsed][Procedo::Procedure.find(params[:parsed][:procedure]).parameters.find {|param| param.type == :target}.name].to_a.each do |target|
          target_attributes.push({reference_name: Procedo::Procedure.find(params[:parsed][:procedure]).parameters.find {|param| param.type == :target}.name, product_id: target[:key], working_zone: Product.find_by_id(target[:key]).shape})
        end 
        # Add each target from specified cropgroups
        params[:parsed][:crop_groups].to_a.each do |cropgroup|
          CropGroup.available_crops(cropgroup[:key], "is plant or is land_parcel").each do |crop|
            target_attributes.push({reference_name: Procedo::Procedure.find(params[:parsed][:procedure]).parameters.find {|param| param.type == :target}.name, product_id: crop[:id], working_zone: Product.find_by_id(crop[:id]).shape})
          end
        end
      end 
      # Add Readings to *_attributes if exists
      params[:parsed][:readings].delete_if{|k,v| !v.present?}.each do |key, rd|
        eval("#{key}_attributes").each do |attr|
          attr[:readings_attributes] = rd.map{|rding| ActiveSupport::HashWithIndifferentAccess.new(rding)}
        end 
      end 
      duration = params[:parsed][:duration].to_i
      date = params[:parsed][:date]
      # Finally save intervention
      intervention = Intervention.create!(procedure_name: params[:parsed][:procedure],
                                          description: "Duke : #{params[:parsed][:user_input]}",
                                          state: 'done',
                                          number: '50',
                                          nature: 'record',
                                          tools_attributes: tool_attributes,
                                          doers_attributes: doer_attributes,
                                          targets_attributes: target_attributes,
                                          inputs_attributes: input_attributes,
                                          working_periods_attributes:   [ { started_at: Time.zone.parse(date) , stopped_at: Time.zone.parse(date) + duration.minutes}])
      return {link: "/backend/interventions/#{intervention.id}"}
    end
  end
end
