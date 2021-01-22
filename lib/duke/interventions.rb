module Duke
  class Interventions

    def handle_parse_sentence(params)
      # First parsing inside interventions
      # params procedure      -> Procedure_name 
      #        user_input     -> Sentence inputed by the user 
      #        procedure_word -> Word in user_input that matched a procedure
      dukeInt = Duke::Models::DukeIntervention.new(procedure: params[:procedure], user_input: params[:user_input])
      return dukeInt.guide_to_procedure unless dukeInt.ok_procedure? # help user find his procedure if current_proc is not accepted
      dukeInt.parse_sentence(proc_word: params[:procedure_word]) # Parse user sentence
      byebug
      return dukeInt.to_ibm(modifiable: dukeInt.modification_candidates) # return Json with what'll be displayed on .click modify-btn
    end

    def handle_modify_specific(params)
      # Function called when user wants to modify one of his specific entities
      # params parsed     -> previously parsed items 
      #        user_input -> Sentence inputed by the user 
      #        specific   -> Type of specific to be parsed (target, input, doer ..)
      byebug
      dukeInt = Duke::Models::DukeIntervention.new.recover_from_hash(params[:parsed])
      tmpInt = Duke::Models::DukeIntervention.new(procedure: dukeInt.procedure,  date: dukeInt.date, user_input: params[:user_input])
      tmpInt.parse_specific(params[:specific])
      dukeInt.join_specific(int: tmpInt, specific: params[:specific])
      return dukeInt.to_ibm
    end

    def handle_modify_temporality(params)
      # Function called when user wants to modify his intervention's temporality
      # params : user_input -> Sentence inputed by the user 
      #          parsed     -> What was previously parsed
      dukeInt = Duke::Models::DukeIntervention.new.recover_from_hash(params[:parsed])
      tmpInt = Duke::Models::DukeIntervention.new(procedure: dukeInt.procedure,  date: dukeInt.date, user_input: params[:user_input])
      tmpInt.parse_temporality
      dukeInt.join_temporality(tmpInt)
      return dukeInt.to_ibm
    end

    def handle_parse_input_quantity(params)
      # function called to parse a number corresponding to the number of "unit_name" of an input, when no rate was specified
      # params : user_input -> Sentence inputed by the user 
      #          parsed     -> What was previously parsed 
      #          quantity   -> Number parsed by IBM 
      #          optional   -> Index of input that needs modification inside parsed[:inputs], Integer
      dukeInt = Duke::Models::DukeIntervention.new.recover_from_hash(params[:parsed])
      value = dukeInt.extract_number_parameter(params[:quantity])
      unless val.nil? 
        # Otherwise add value for the given input (we get it via it's index in parsed[:inputs])
        dukeInt.inputs[params[:optional]][:rate][:value] = value 
        dukeInt.update_description(params[:user_input])
        dukeInt.reset_retries
      end 
      return dukeInt.to_ibm
    end

    def handle_parse_which_target(params) 
      # Function called to find which targets were selected by the user when multiple choice is available for vegetal procedures
      # params : user_input -> Sentence inputed by the user 
      #          parsed     -> What was previously parsed 
      dukeInt = Duke::Models::DukeIntervention.new.recover_from_hash(params[:parsed])
      dukeInt.user_input = params[:user_input] 
      dukeInt.parse_multiple_targets
      return dukeInt.to_ibm
    end 

    def handle_parse_disambiguation(params)
      # Handle disambiguation when users returns a choice.
      # params : user_input -> Sentence inputed by the user, or data the user clicked
      #          parsed     -> What was previously parsed 
      #          optional   -> The JSON with every ambiguity choices, the title, and the description
      dukeInt = Duke::Models::DukeIntervention.new.recover_from_hash(params[:parsed])
      # TODO : Create a OptJson object
      # Retrieving id of element we'll modify
      current_id = params[:optional].first[:description][:id]
      # Find the type of element (:input, :plant ..) and the corresponding array from the previously parsed items, then find the correct hash
      current_type, current_array = dukeInt.to_jsonD.find { |key, value| value.is_a?(Array) and value.any? { |subhash| subhash[:key] == current_id}}
      current_hash = current_array.find {|hash| hash[:key] == current_id}
      current_array.delete(current_hash)
      begin
        # If the user_input can be turned to hash(es) splitted by ||| -> user clicked on value(s), we replace the name & key from the previously chosen one
        params[:user_input].split(/[|]{3}/).map{|chosen| eval(chosen)}.each do |chosen_one| 
          current_array.push(current_hash.merge(chosen_one))
          # If the type of ambiguation is an input, make sure quantity handlers are concording with new input, otherwise remove rate infos
          if current_type.to_sym == :inputs && (([:net_mass, :mass_area_density].include? current_hash[:rate][:unit].to_sym and Matter.find_by_id(current_hash[:key])&.net_mass.to_f == 0) || ([:net_volume, :volume_area_density].include? current_hash[:rate][:unit].to_sym and Matter.find_by_id(current_hash[:key])&.net_volume.fo_f == 0))
              current_hash[:rate][:unit] = :population 
              current_hash[:rate][:value] = nil 
          end 
        end 
      rescue
        nil
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
