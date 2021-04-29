module Duke
  module Skill
    module HarvestReceptions
      class ParseSentence < Duke::Skill::DukeHarvestReception
        using Duke::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input)
          @event = event
        end 

        def handle
          parse_sentence
          to_ibm
        end
        
      end
    end
  end
end