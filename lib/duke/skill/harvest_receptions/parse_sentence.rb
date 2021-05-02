module Duke
  module Skill
    module HarvestReceptions
      class ParseSentence < Duke::Skill::DukeHarvestReception

        def initialize(event)
          super(user_input: event.user_input)
          @event = event
        end

        def handle
          parse_sentence
          to_ibm
        end

        private

          #  Extracts everything it can from a sentence
          def parse_sentence
            extract_date
            extract_reception_parameters
            extract_user_specifics
            extract_plant_area
            find_ambiguity
          end

      end
    end
  end
end
