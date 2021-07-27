module Duke
  module Skill
    module Durability
      module A1
        class PlantAssociations < Durability::IdeaArticle

          def initialize(event)
            super(event, 'A1')
          end

          def handle
            item('A1_3').set!(@event.options.number.to_i, :integer)
            @component.update_global_score
            DukeResponse.new
          end

        end
      end
    end
  end
end
