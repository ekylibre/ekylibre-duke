module Duke
  module Skill
    module HarvestReceptions
      class AddOther < Duke::Skill::DukeHarvestReception

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end

        # Does nothing redirects to save panel with current intervention
        def handle
          to_ibm
        end

      end
    end
  end
end
