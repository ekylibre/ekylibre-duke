module Duke
  module Skill
    module HarvestReceptions
      class ParseTargets < Duke::Skill::DukeHarvestReception
        using Duke::DukeRefinements

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end 

        def handle
          newHarv = Duke::Skill::DukeHarvestReception.new(user_input: @event.user_input)
          newHarv.parse_specifics(:plant, :crop_groups, :date)
          update_targets(newHarv)
          adjust_retries(@event.options.previous)  # @current_asking to options.preious
          to_ibm
        end
        
      end
    end
  end
end