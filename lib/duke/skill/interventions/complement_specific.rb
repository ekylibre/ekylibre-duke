module Duke
  module Skill
    module Interventions
      class ComplementSpecific < Duke::Skill::DukeIntervention

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end

        # Look for specific item to be added to intervention
        # options specific: what we're looking for (tool || target || input || doer)
        def handle
          tmp_int = Duke::Skill::DukeIntervention.new.recover_from_hash(@event.parsed)
          tmp_int.user_input = @event.user_input
          tmp_int.parse_specific_buttons(@event.options.specific)
          concat_specific(int: tmp_int)
          to_ibm(modifiable: modification_candidates)
        end

      end
    end
  end
end
