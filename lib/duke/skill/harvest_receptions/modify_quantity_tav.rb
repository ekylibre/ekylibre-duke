module Duke
  module Skill
    module HarvestReceptions
      class ModifyQuantityTav < Duke::Skill::DukeHarvestReception
        using Duke::DukeRefinements

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end 

        def handle
          newHarv = Duke::Skill::DukeHarvestReception.new(user_input: @event.user_input)
          newHarv.extract_quantity_tavp
          ['quantity', 'tav'].each do |attr| 
            @parameters[attr] = newHarv.parameters[attr] unless newHarv.parameters[attr].nil?
          end 
          update_description(@event.user_input)
          to_ibm
        end

        private 

        # Perform Quantity/Tavp regex extractions 
        def extract_quantity_tavp
          extract_quantity
          extract_conflicting_degrees
          extract_tav
        end 

        def extract_quantity
          # Extracting quantity data
          quantity = @user_input.matchdel(Duke::Utils::Regex.quantity)
          if quantity
            unit = if quantity[3].match(/(kilo|kg)/)
                    "kg" 
                    elsif quantity[3].match(/(hecto|hl|texto|expo)/)
                    "hl"
                    else
                    "t"
                    end
            @parameters['quantity'] = {"rate" => quantity[1].gsub(',','.').to_f, "unit" => unit} # rate is the first capturing group
          else
            @parameters['quantity'] = nil
          end
        end
        
      end
    end
  end
end