module Duke
  module Skill
    module Interventions
      class ModifyTemporality < Duke::Skill::DukeIntervention
        using Duke::DukeRefinements

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end 

        def handle
          tmpInt = Duke::Skill::DukeIntervention.new(procedure: @procedure,  date: @date, user_input: @event.user_input)
          tmpInt.extract_date_and_duration
          concat_specific(int: tmpInt)
          join_temporality(tmpInt)
          to_ibm
        end
      
      end
    end
  end
end
