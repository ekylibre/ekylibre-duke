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
        
      end
    end
  end
end