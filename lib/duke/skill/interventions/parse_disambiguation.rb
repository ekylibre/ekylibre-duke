module Duke
  module Skill
    module Interventions
      class ParseDisambiguation < Duke::Skill::DukeIntervention

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end

        # Handles disambiguation
        def handle
          @user_input = @event.user_input
          correct_ambiguity(type: @event.options.ambiguity_type, key: @event.options.ambiguity_key)
          to_ibm
        end

      end
    end
  end
end
