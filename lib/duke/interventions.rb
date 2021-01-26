module Duke
  class Interventions

    # @params [procedure] String : procedure_name
    # @params [user_input] String : User Utterance
    # @params [procedure_word] String : Literal procedure word
    def handle_parse_sentence(params)
      dukeInt = Duke::Models::DukeIntervention.new(procedure: params[:procedure], user_input: params[:user_input])
      return dukeInt.guide_to_procedure unless dukeInt.ok_procedure? # help user find his procedure if current_proc is not accepted
      dukeInt.parse_sentence(proc_word: params[:procedure_word]) # Parse user sentence
      return dukeInt.to_ibm(modifiable: dukeInt.modification_candidates) # return Json with what'll be displayed on .click modify-btn
    end

    # @params [parsed] Json : Previously parsed
    # @params [user_input] String : User Utterance
    # @params [specific] String : What we want to modify
    def handle_modify_specific(params)
      dukeInt = Duke::Models::DukeIntervention.new.recover_from_hash(params[:parsed])
      tmpInt = Duke::Models::DukeIntervention.new(procedure: dukeInt.procedure,  date: dukeInt.date, user_input: params[:user_input])
      tmpInt.parse_specific(params[:specific])
      dukeInt.join_specific(int: tmpInt, sp: params[:specific])
      return dukeInt.to_ibm
    end

    # @params [parsed] Json : Previously parsed
    # @params [user_input] String : User Utterance
    def handle_modify_temporality(params)
      dukeInt = Duke::Models::DukeIntervention.new.recover_from_hash(params[:parsed])
      tmpInt = Duke::Models::DukeIntervention.new(procedure: dukeInt.procedure,  date: dukeInt.date, user_input: params[:user_input])
      tmpInt.parse_temporality
      dukeInt.join_temporality(tmpInt)
      return dukeInt.to_ibm
    end

    # @params [parsed] Json : Previously parsed
    # @params [user_input] String : User Utterance
    # @params [quantity] Integer : Number parsed by IBM 
    # @params [optional] Integer : Index of input that needs modif
    def handle_parse_input_quantity(params)
      dukeInt = Duke::Models::DukeIntervention.new.recover_from_hash(params[:parsed])
      value = dukeInt.extract_number_parameter(params[:quantity])
      unless value.nil? 
        # Otherwise add value for the given input (we get it via it's index in parsed[:inputs])
        dukeInt.inputs[params[:optional]][:rate][:value] = value 
        dukeInt.update_description(params[:user_input])
        dukeInt.reset_retries
      end 
      return dukeInt.to_ibm
    end

    # @params [parsed] Json : Previously parsed
    # @params [user_input] String : User Utterance
    def handle_parse_which_target(params) 
      dukeInt = Duke::Models::DukeIntervention.new.recover_from_hash(params[:parsed])
      dukeInt.user_input = params[:user_input] 
      dukeInt.parse_multiple_targets
      return dukeInt.to_ibm
    end 

    # @params [parsed] Json : Previously parsed
    # @params [user_input] String : User Utterance
    # @params [amb_key] Integer : Key of ambiguous element
    # @params [amb_type] String : Type of ambiguous element
    def handle_parse_disambiguation(params)
      dukeInt = Duke::Models::DukeIntervention.new.recover_from_hash(params[:parsed])
      dukeInt.user_input = params[:user_input]
      dukeInt.correct_ambiguity(type: params[:amb_type], key: params[:amb_key])
      return dukeInt.to_ibm
    end

    # @params [parsed] Json : Previously parsed
    def handle_save_intervention(params)
      dukeInt = Duke::Models::DukeIntervention.new.recover_from_hash(params[:parsed])
      id = dukeInt.save_intervention 
      return {link: "/backend/interventions/#{id}"}
    end
  end
end
