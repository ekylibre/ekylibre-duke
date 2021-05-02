module Duke
  module Skill
    module Interventions
      class ModifySpecific < Duke::Skill::DukeIntervention
        using Duke::DukeRefinements

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end

        def handle
          tmp_int = Duke::Skill::DukeIntervention.new(procedure: @procedure,  date: @date, user_input: @event.user_input)
          tmp_int.parse_specific(@event.options.specific)
          replace_specific(int: tmp_int)
          to_ibm
        end

        private

          # @param [DukeIntervention] int : previous DukeIntervention
          def replace_specific(int:)
            specific_json = int.duke_json(int.specific, :ambiguities)
            self.recover_from_hash(self.duke_json.merge(specific_json))
            self.update_description(int.description)
          end

      end
    end
  end
end
