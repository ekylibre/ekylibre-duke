module Duke
  module Skill
    module HarvestReceptions
      class ParseParameter < Duke::Skill::DukeHarvestReception
        using Duke::DukeRefinements

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end 

        def handle
          @user_input = @event.user_input
          value = extract_number_parameter(@event.options.quantity) # modify @value in options.quantity
          unless value.nil?
            add_parameter(@event.options.specific, value) # modify @parameter in options.specific
            update_description(@event.user_input)
            reset_retries
          end 
          to_ibm
        end
        
      end
    end
  end
end