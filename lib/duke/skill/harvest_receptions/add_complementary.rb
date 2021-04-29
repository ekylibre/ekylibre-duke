module Duke
  module Skill
    module HarvestReceptions
      class AddComplementary < Duke::Skill::DukeHarvestReception
        using Duke::DukeRefinements

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end 

        def handle
          @user_input = @event.user_input
          update_complementary(@event.options.specific) # modify parameter to options.specific 
          to_ibm
        end
        
      end
    end
  end
end