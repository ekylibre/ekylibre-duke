module Duke
  module Skill
    module HarvestReceptions
      class ModifyDate < Duke::Skill::DukeHarvestReception

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end

        # Modify date and hour of incoming harvest
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
