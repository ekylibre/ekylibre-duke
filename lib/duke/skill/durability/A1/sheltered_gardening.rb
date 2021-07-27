module Duke
  module Skill
    module Durability
      module A1
        class ShelteredGardening < Durability::IdeaArticle
          using Duke::Utils::DukeRefinements
          include Duke::Utils::BaseDuke

          def initialize(event)
            super(event, 'A1')
          end

          def handle
            item('A1_1').set!(@event.user_input, :string)
            @component.update_global_score
            DukeResponse.new
          end

        end
      end
    end
  end
end
