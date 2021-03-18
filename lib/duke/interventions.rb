module Duke
  class Interventions
    using Duke::DukeRefinements

    # Common @params : 
    #   [Json] parsed : Previously parsed
    #   [String] user_input : User Utterance

    # First entry into Intervention Skill
    # @params [String] procedure_word : Literal procedure word
    def handle_parse_sentence params
      dukeInt = Duke::DukeIntervention.new(procedure: params[:procedure], user_input: params[:user_input])
      return dukeInt.guide_to_procedure unless dukeInt.ok_procedure? # help user find his procedure if current_proc is not accepted
      dukeInt.parse_sentence(proc_word: params[:procedure_word]) # Parse user sentence
      return dukeInt.to_ibm(modifiable: dukeInt.modification_candidates, moreable: dukeInt.complement_candidates) # return Json with what'll be displayed on .click modify-btn
    end

    # Modify a specific type of element
    # @params [String] specific : What we want to modify
    def handle_modify_specific params
      dukeInt = Duke::DukeIntervention.new.recover_from_hash(params[:parsed])
      tmpInt = Duke::DukeIntervention.new(procedure: dukeInt.procedure,  date: dukeInt.date, user_input: params[:user_input])
      tmpInt.parse_specific(params[:specific])
      dukeInt.replace_specific(int: tmpInt)
      return dukeInt.to_ibm
    end

    # Add a specific type of element
    # @params [String] specific : What we want to modify
    def handle_complement_specific params
      dukeInt = Duke::DukeIntervention.new.recover_from_hash(params[:parsed])
      tmpInt = Duke::DukeIntervention.new(procedure: dukeInt.procedure,  date: dukeInt.date, user_input: params[:user_input])
      tmpInt.parse_specific_buttons(params[:specific]) 
      dukeInt.concat_specific(int: tmpInt)
      return dukeInt.to_ibm(modifiable: dukeInt.modification_candidates)
    end 

    # @return [Json] clickable options with all 'type' elements
    # @params [String] type: Type of items we want to display
    def handle_get_complement_items params 
      dukeInt = Duke::DukeIntervention.new.recover_from_hash(params[:parsed])
      return dukeInt.to_ibm(optionAll: dukeInt.optionAll(params[:type]))
    end 

    # Add element(s) from everything available
    def handle_complement_anything params 
      dukeInt = Duke::DukeIntervention.new.recover_from_hash(params[:parsed])
      tmpInt = Duke::DukeIntervention.new(procedure: dukeInt.procedure,  date: dukeInt.date, user_input: params[:user_input])
      tmpInt.parse_sentence
      dukeInt.concat_specific(int: tmpInt)
      return dukeInt.to_ibm(modifiable: dukeInt.modification_candidates)
    end 

    # Modify intervention date and duration
    def handle_modify_temporality params
      dukeInt = Duke::DukeIntervention.new.recover_from_hash(params[:parsed])
      tmpInt = Duke::DukeIntervention.new(procedure: dukeInt.procedure,  date: dukeInt.date, user_input: params[:user_input])
      tmpInt.extract_date_and_duration
      dukeInt.join_temporality(tmpInt)
      return dukeInt.to_ibm
    end

    # Add working period(s)
    def handle_complement_working_periods params 
      dukeInt = Duke::DukeIntervention.new.recover_from_hash(params[:parsed])
      tmpInt = Duke::DukeIntervention.new(procedure: dukeInt.procedure,  date: dukeInt.date, user_input: params[:user_input].duke_clear)
      tmpInt.extract_wp_from_interval(tmpInt.user_input)
      dukeInt.add_working_interval(tmpInt.working_periods)
      return dukeInt.to_ibm
    end 

    # @params [Integer] quantity : Number parsed by IBM 
    # @params [Integer] optional : Index of input that needs modif
    # Parse input quantity when asked to user
    def handle_parse_input_quantity params
      dukeInt = Duke::DukeIntervention.new.recover_from_hash(params[:parsed])
      dukeInt.user_input = params[:user_input]
      value = dukeInt.extract_number_parameter(params[:quantity])
      unless value.nil? # Otherwise add value for the given input (we get it via it's index in parsed[:input])
        dukeInt.input[params[:optional]][:rate][:value] = value 
        dukeInt.update_description(params[:user_input])
        dukeInt.reset_retries
      end 
      return dukeInt.to_ibm
    end

    # @params [Integer] amb_key : Key of ambiguous element
    # @params [String] amb_type : Type of ambiguous element
    # Disambiguate an element
    def handle_parse_disambiguation params
      dukeInt = Duke::DukeIntervention.new.recover_from_hash(params[:parsed])
      dukeInt.user_input = params[:user_input]
      dukeInt.correct_ambiguity(type: params[:amb_type], key: params[:amb_key])
      return dukeInt.to_ibm
    end

    # Creates intervention 
    # @return [Json] link to intervention
    def handle_save_intervention params
      dukeInt = Duke::DukeIntervention.new.recover_from_hash(params[:parsed])
      id = dukeInt.save_intervention 
      return {link: "/backend/interventions/#{id}"}
    end
  end
end
