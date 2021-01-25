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
      return dukeInt.to_ibm(modifiable: dukeInt.modification_candidates) # return Json with what'll be displayed on .click modify-btn
    end

    def handle_modify_specific(params)
      # Function called when user wants to modify one of his specific entities
      # params parsed     -> previously parsed items 
      #        user_input -> Sentence inputed by the user 
      #        specific   -> Type of specific to be parsed (target, input, doer ..)
      dukeInt = Duke::Models::DukeIntervention.new.recover_from_hash(params[:parsed])
      tmpInt = Duke::Models::DukeIntervention.new(procedure: dukeInt.procedure,  date: dukeInt.date, user_input: params[:user_input])
      tmpInt.parse_specific(params[:specific])
      dukeInt.join_specific(int: tmpInt, sp: params[:specific])
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
      dukeInt.user_input = params[:user_input]
      dukeInt.correct_ambiguity(type: params[:amb_type], key: params[:amb_key])
      return dukeInt.to_ibm
    end

    def handle_save_intervention(params)
      # Function that's called when user press "save" button
      # Saves intervention & returns the link to it, to interface-redirect user
      # params : parsed     -> What was previously parsed 
      dukeInt = Duke::Models::DukeIntervention.new.recover_from_hash(params[:parsed])
      id = dukeInt.save_intervention 
      # Finally save intervention
      return {link: "/backend/interventions/#{id}"}
    end
  end
end
