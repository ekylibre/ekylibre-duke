module Duke
  class HarvestReceptions < Duke::Models::DukeHarvestReception

    # @params [String] user_input
    def handle_parse_sentence(params)
      dukeHarv = Duke::Models::DukeHarvestReception.new(user_input: params[:user_input])
      dukeHarv.parse_sentence
      return dukeHarv.to_ibm
    end

    # @param [String] user_input 
    # @param [Json] parsed 
    # @param [String] parameter : type of param to parse
    # @param [Integer] value: Integer parsed by IBM
    def handle_parse_parameter(params)
      dukeHarv = Duke::Models::DukeHarvestReception.new.recover_from_hash(params[:parsed])
      dukeHarv.user_input = params[:user_input]
      value = dukeHarv.extract_number_parameter(params[:value])
      unless value.nil? 
        dukeHarv.add_parameter(params[:parameter], value)
        dukeHarv.update_description(params[:user_input])
        dukeHarv.reset_retries
      end 
      return dukeHarv.to_ibm
    end

    # @param [String] user_input 
    # @param [Json] parsed 
    def handle_modify_quantity_tav(params)
      dukeHarv = Duke::Models::DukeHarvestReception.new.recover_from_hash(params[:parsed])
      newHarv = Duke::Models::DukeHarvestReception.new(user_input: params[:user_input])
      newHarv.extract_quantity_tavp
      ['quantity', 'tav'].each do |attr| 
        dukeHarv.parameters[attr] = newHarv.parameters[attr] unless newHarv.parameters[attr].nil?
      end 
      dukeHarv.update_description(params[:user_input])
      return dukeHarv.to_ibm
    end

    # @param [String] user_input 
    # @param [Json] parsed 
    def handle_modify_date(params)
      dukeHarv = Duke::Models::DukeHarvestReception.new.recover_from_hash(params[:parsed])
      dukeHarv.user_input = params[:user_input]
      dukeHarv.extract_date
      dukeHarv.update_description(params[:user_input])
      return dukeHarv.to_ibm
    end

    # @param [String] user_input 
    # @param [Json] parsed 
    # @param [Integer] optional : index of destination that needs modification
    # @param [String] parameter : "press"||"destination" 
    def handle_parse_destination_quantity(params)
      dukeHarv = Duke::Models::DukeHarvestReception.new.recover_from_hash(params[:parsed])
      dukeHarv.user_input = params[:user_input]
      value = dukeHarv.extract_number_parameter(params[:value])
      unless value.nil? 
        dukeHarv.send("update_#{params[:parameter]}_quantity", params[:optional], value)
        dukeHarv.update_description(params[:user_input])
        dukeHarv.reset_retries
      end 
      return dukeHarv.to_ibm
    end 

    # @param [String] user_input 
    # @param [Json] parsed 
    # @param [String] current_asking : Previous redirect
    def handle_parse_targets(params)
      dukeHarv = Duke::Models::DukeHarvestReception.new.recover_from_hash(params[:parsed])
      newHarv = Duke::Models::DukeHarvestReception.new(user_input: params[:user_input])
      newHarv.parse_specifics(:plant, :crop_groups, :date)
      dukeHarv.update_targets(newHarv)
      dukeHarv.adjust_retries params[:current_asking]
      return dukeHarv.to_ibm
    end

    # @param [String] user_input 
    # @param [Json] parsed 
    # @param [String] current_asking : Previous redirect
    # @param [Integer] optional : Previous optional
    def handle_parse_destination(params)
      dukeHarv = Duke::Models::DukeHarvestReception.new.recover_from_hash(params[:parsed])
      newHarv = Duke::Models::DukeHarvestReception.new(user_input: params[:user_input])
      newHarv.parse_specifics(:destination, :date)
      dukeHarv.update_destination newHarv
      dukeHarv.adjust_retries(params[:current_asking], optional=params[:optional])
      return dukeHarv.to_ibm
    end

    # @param [String] user_input 
    # @param [Json] parsed 
    def handle_add_other(params)
      dukeHarv = Duke::Models::DukeHarvestReception.new.recover_from_hash(params[:parsed])
      return dukeHarv.to_ibm
    end

    # @params [parsed] Json : Previously parsed
    # @params [user_input] String : User Utterance
    # @params [amb_key] Integer : Key of ambiguous element
    # @params [amb_type] String : Type of ambiguous element
    def handle_parse_disambiguation(params)
      dukeHarv = Duke::Models::DukeHarvestReception.new.recover_from_hash(params[:parsed])
      dukeHarv.user_input = params[:user_input]
      dukeHarv.correct_ambiguity(type: params[:amb_type], key: params[:amb_key])
      return dukeHarv.to_ibm
    end

    # @param [String] user_input 
    # @param [Json] parsed 
    def handle_add_analysis(params)
      dukeHarv = Duke::Models::DukeHarvestReception.new.recover_from_hash(params[:parsed])
      newHarv = Duke::Models::DukeHarvestReception.new(user_input: params[:user_input])
      newHarv.extract_reception_parameters(post_harvest=true)
      dukeHarv.concatenate_analysis(newHarv)
      dukeHarv.update_description(params[:user_input])
      return dukeHarv.to_ibm
    end

    # @param [String] user_input 
    # @param [Json] parsed 
    def handle_add_pressing(params)
      dukeHarv = Duke::Models::DukeHarvestReception.new.recover_from_hash(params[:parsed])
      newHarv = Duke::Models::DukeHarvestReception.new(user_input: params[:user_input])
      newHarv.parse_specifics(:press, :date)
      dukeHarv.update_press(newHarv)
      dukeHarv.adjust_retries params[:current_asking]
      return dukeHarv.to_ibm
    end

    # @param [String] user_input 
    # @param [Json] parsed 
    # @param [String] parameter : Type of complementary to add
    def handle_add_complementary(params)
      dukeHarv = Duke::Models::DukeHarvestReception.new.recover_from_hash(params[:parsed])
      dukeHarv.user_input = params[:user_input]
      dukeHarv.update_complementary params[:parameter]
      return dukeHarv.to_ibm
    end

    # @param [Json] parsed 
    def handle_save_harvest_reception(params)
      dukeHarv = Duke::Models::DukeHarvestReception.new.recover_from_hash(params[:parsed])
      id = dukeHarv.save_harvest_reception
      return {link: "/backend/wine_incoming_harvests/#{id}"}
    end
  end
end
