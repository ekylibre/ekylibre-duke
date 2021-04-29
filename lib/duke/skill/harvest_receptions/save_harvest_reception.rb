module Duke
  module Skill
    module HarvestReceptions
      class SaveHarvestReception < Duke::Skill::DukeHarvestReception
        using Duke::DukeRefinements

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
        end 

        def handle
          Duke::DukeResponse.new(sentence: I18n.t("duke.harvest_receptions.saved", id: save_harvest_reception)) 
        end
        
      end
    end
  end
end