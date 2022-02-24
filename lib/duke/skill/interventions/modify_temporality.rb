module Duke
  module Skill
    module Interventions
      class ModifyTemporality < Duke::Skill::DukeIntervention

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end

        # Modify date and duration
        # Keeps duration if only date is changed and opposite
        # Keeps hour if only day is changed
        def handle
          tmp_int = Duke::Skill::DukeIntervention.new(procedure: @procedure,  date: @date, user_input: @event.user_input)
          tmp_int.extract_date_and_duration
          join_temporality(tmp_int)
          to_ibm
        end

      end
    end
  end
end
