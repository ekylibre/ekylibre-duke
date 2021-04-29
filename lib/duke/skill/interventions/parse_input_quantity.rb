module Duke
  module Skill
    module Interventions
      class ParseInputQuantity < Duke::Skill::DukeIntervention
        using Duke::DukeRefinements

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end 

        def handle
          byebug
          @user_input = @event.user_input
          value = extract_number_parameter(@event.options.quantity)
          if value.present?
            @input[@event.options.index][:rate][:value] = value 
            reset_retries
            update_description(@event.user_input)
          end 
          to_ibm
        end
      
      end
    end
  end
end