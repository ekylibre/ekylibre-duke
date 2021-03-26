module Duke
  module Skill
    class HarvestReceptions

      # Common @params : 
      #   [Json] parsed : Previously parsed
      #   [String] user_input : User Utterance

      # First entry into HarvestReception skill
      # @params [String] user_input
      def handle_parse_sentence(params)
        dukeHarv = Duke::DukeHarvestReception.new(user_input: params[:user_input])
        dukeHarv.parse_sentence
        return dukeHarv.to_ibm
      end

      # Parse Tavp or quantity number value
      # @param [String] parameter : type of param to parse
      # @param [Integer] value: Integer parsed by IBM
      def handle_parse_parameter(params)
        dukeHarv = Duke::DukeHarvestReception.new.recover_from_hash(params[:parsed])
        dukeHarv.user_input = params[:user_input]
        value = dukeHarv.extract_number_parameter(params[:value])
        unless value.nil? 
          dukeHarv.add_parameter(params[:parameter], value)
          dukeHarv.update_description(params[:user_input])
          dukeHarv.reset_retries
        end 
        return dukeHarv.to_ibm
      end
      
      # Modify Tavp or quantity value
      def handle_modify_quantity_tav(params)
        dukeHarv = Duke::DukeHarvestReception.new.recover_from_hash(params[:parsed])
        newHarv = Duke::DukeHarvestReception.new(user_input: params[:user_input])
        newHarv.extract_quantity_tavp
        ['quantity', 'tav'].each do |attr| 
          dukeHarv.parameters[attr] = newHarv.parameters[attr] unless newHarv.parameters[attr].nil?
        end 
        dukeHarv.update_description(params[:user_input])
        return dukeHarv.to_ibm
      end

      # Modify harvest reception date
      def handle_modify_date(params)
        dukeHarv = Duke::DukeHarvestReception.new.recover_from_hash(params[:parsed])
        dukeHarv.user_input = params[:user_input]
        dukeHarv.extract_date
        dukeHarv.update_description(params[:user_input])
        return dukeHarv.to_ibm
      end

      # Parse quantity for a specific destination
      # @param [Integer] optional : index of destination that needs modification
      # @param [String] parameter : "press"||"destination" 
      def handle_parse_destination_quantity(params)
        dukeHarv = Duke::DukeHarvestReception.new.recover_from_hash(params[:parsed])
        dukeHarv.user_input = params[:user_input]
        value = dukeHarv.extract_number_parameter(params[:value])
        unless value.nil? 
          dukeHarv.send("update_#{params[:parameter]}_quantity", params[:optional], value)
          dukeHarv.update_description(params[:user_input])
          dukeHarv.reset_retries
        end 
        return dukeHarv.to_ibm
      end 

      # Find plants in user utterance
      # @param [String] current_asking : Previous redirect
      def handle_parse_targets(params)
        dukeHarv = Duke::DukeHarvestReception.new.recover_from_hash(params[:parsed])
        newHarv = Duke::DukeHarvestReception.new(user_input: params[:user_input])
        newHarv.parse_specifics(:plant, :crop_groups, :date)
        dukeHarv.update_targets(newHarv)
        dukeHarv.adjust_retries params[:current_asking]
        return dukeHarv.to_ibm
      end

      # Find destination in user_utterance
      # @param [String] current_asking : Previous redirect
      # @param [Integer] optional : Previous optional
      def handle_parse_destination(params)
        dukeHarv = Duke::DukeHarvestReception.new.recover_from_hash(params[:parsed])
        newHarv = Duke::DukeHarvestReception.new(user_input: params[:user_input])
        newHarv.parse_specifics(:destination, :date)
        dukeHarv.update_destination newHarv
        dukeHarv.adjust_retries(params[:current_asking], optional=params[:optional])
        return dukeHarv.to_ibm
      end

      # Rerouting to basic menu
      def handle_add_other(params)
        dukeHarv = Duke::DukeHarvestReception.new.recover_from_hash(params[:parsed])
        return dukeHarv.to_ibm
      end

      # Disambiguate an item
      # @params [amb_key] Integer : Key of ambiguous element
      # @params [amb_type] String : Type of ambiguous element
      def handle_parse_disambiguation(params)
        dukeHarv = Duke::DukeHarvestReception.new.recover_from_hash(params[:parsed])
        dukeHarv.user_input = params[:user_input]
        dukeHarv.correct_ambiguity(type: params[:amb_type], key: params[:amb_key])
        return dukeHarv.to_ibm
      end

      # Complement analysis elements
      def handle_add_analysis(params)
        dukeHarv = Duke::DukeHarvestReception.new.recover_from_hash(params[:parsed])
        newHarv = Duke::DukeHarvestReception.new(user_input: params[:user_input])
        newHarv.extract_reception_parameters(post_harvest=true)
        dukeHarv.concatenate_analysis(newHarv)
        dukeHarv.update_description(params[:user_input])
        return dukeHarv.to_ibm
      end

      # Complement with press(es)
      def handle_add_pressing(params)
        dukeHarv = Duke::DukeHarvestReception.new.recover_from_hash(params[:parsed])
        newHarv = Duke::DukeHarvestReception.new(user_input: params[:user_input])
        newHarv.parse_specifics(:press, :date)
        dukeHarv.update_press(newHarv)
        dukeHarv.adjust_retries params[:current_asking]
        return dukeHarv.to_ibm
      end

      # Add complementary parameter
      # @param [String] parameter : Type of complementary to add
      def handle_add_complementary(params)
        dukeHarv = Duke::DukeHarvestReception.new.recover_from_hash(params[:parsed])
        dukeHarv.user_input = params[:user_input]
        dukeHarv.update_complementary params[:parameter]
        return dukeHarv.to_ibm
      end

      # Save harvest reception 
      # @return [Json] link to harvest reception
      def handle_save_harvest_reception(params)
        dukeHarv = Duke::DukeHarvestReception.new.recover_from_hash(params[:parsed])
        dukeHarv.save_harvest_reception
        return dukeHarv.front_redirection
      end
    end
  end
end
