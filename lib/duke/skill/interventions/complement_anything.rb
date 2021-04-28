module Duke
  module Skill
    module Interventions
      class ComplementAnything < Duke::Skill::DukeIntervention
        using Duke::DukeRefinements

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end 

        def handle
          tmpInt = Duke::Skill::DukeIntervention.new(procedure: @procedure,  date: @date, user_input: @event.user_input)
          tmpInt.parse_sentence
          concat_specific(int: tmpInt)
          to_ibm(modifiable: modification_candidates)
        end
        
      end
    end
  end
end