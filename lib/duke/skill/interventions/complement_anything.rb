module Duke
  module Skill
    module Interventions
      class ComplementAnything < Duke::Skill::DukeIntervention

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end

        # Looks for anything that can be added to intervention
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
