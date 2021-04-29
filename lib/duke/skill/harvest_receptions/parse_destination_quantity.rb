module Duke
  module Skill
    module HarvestReceptions
      class ParseDestinationQuantity < Duke::Skill::DukeHarvestReception
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
            send("update_#{@event.options.specific}_quantity", @event.options.index, value) # modify @optional in options.index && @parameter in options.specific
            update_description(@event.user_input)
            reset_retries
          end 
          to_ibm
        end
        
      end
    end
  end
end