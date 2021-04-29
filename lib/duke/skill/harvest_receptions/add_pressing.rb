module Duke
  module Skill
    module HarvestReceptions
      class AddPressing < Duke::Skill::DukeHarvestReception
        using Duke::DukeRefinements

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end 

        def handle
          newHarv = Duke::Skill::DukeHarvestReception.new(user_input: @event.user_input)
          newHarv.parse_specifics(:press, :date)
          update_press(newHarv)
          adjust_retries(@event.options.previous)
          to_ibm
        end
        
      end
    end
  end
end