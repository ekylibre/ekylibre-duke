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
          tmp_int = Duke::Skill::DukeIntervention.new(procedure: @procedure,  date: @date, user_input: @event.user_input)
          tmp_int.parse_sentence
          concat_specific(int: tmp_int)
          to_ibm(modifiable: modification_candidates)
        end

      end
    end
  end
end
