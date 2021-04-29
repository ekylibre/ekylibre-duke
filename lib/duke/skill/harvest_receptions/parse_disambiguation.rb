module Duke
  module Skill
    module HarvestReceptions
      class ParseDisambiguation < Duke::Skill::DukeHarvestReception
        using Duke::DukeRefinements

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end 

        def handle
          @user_input = @event.user_input
          correct_ambiguity(type: @event.options.ambiguity_type, key: @event.options.ambiguity_key)
          to_ibm
        end
        
      end
    end
  end
end