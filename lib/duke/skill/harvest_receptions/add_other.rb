module Duke
  module Skill
    module HarvestReceptions
      class AddOther < Duke::Skill::DukeHarvestReception
        using Duke::DukeRefinements

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end 

        def handle
          to_ibm
        end
        
      end
    end
  end
end