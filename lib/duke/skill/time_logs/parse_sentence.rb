module Duke
  module Skill
    module TimeLogs
      class ParseSentence < Duke::Skill::DukeTimeLog
        using Duke::Utils::DukeRefinements

        attr_accessor :working_entity

        def initialize(event)
          super(user_input: event.user_input)
          @event = event
          @working_entity = DukeMatchingArray.new
          extract_date_and_duration
        end

        # First entry inside intervention. Parse procedure and * else if procedure, else guides user to correct proc
        def handle
          extract_user_specifics(duke_json: self.duke_json(:working_entity, :date, :user_input))
          find_ambiguity
          to_ibm
        end

      end
    end
  end
end
