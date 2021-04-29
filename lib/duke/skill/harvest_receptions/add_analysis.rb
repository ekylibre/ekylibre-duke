module Duke
  module Skill
    module HarvestReceptions
      class AddAnalysis < Duke::Skill::DukeHarvestReception
        using Duke::DukeRefinements

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end 

        def handle
          newHarv = Duke::Skill::DukeHarvestReception.new(user_input: @event.user_input)
          newHarv.extract_reception_parameters(post_harvest=true)
          concatenate_analysis(newHarv)
          update_description(@event.user_input)
          to_ibm
        end
        
      end
    end
  end
end