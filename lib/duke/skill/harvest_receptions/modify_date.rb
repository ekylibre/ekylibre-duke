module Duke
  module Skill
    module HarvestReceptions
      class ModifyDate < Duke::Skill::DukeHarvestReception
        using Duke::DukeRefinements

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end 

        def handle
          @user_input = @event.user_input
          extract_date
          update_description(@event.user_input)
          to_ibm
        end
        
      end
    end
  end
end