module Duke
  module Skill
    module HarvestReceptions
      class ParseDestination < Duke::Skill::DukeHarvestReception
        using Duke::DukeRefinements

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end 

        def handle
          newHarv = Duke::Skill::DukeHarvestReception.new(user_input: @event.user_input)
          newHarv.parse_specifics(:destination, :date)
          update_destination(newHarv)
          adjust_retries(@event.options.previous)  # @current_asking to options.previous, @optional: to remove
          to_ibm
        end
        
      end
    end
  end
end