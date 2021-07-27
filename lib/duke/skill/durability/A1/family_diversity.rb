module Duke
  module Skill
    module Durability
      module A1
        class FamilyDiversity < Durability::IdeaArticle

          def initialize(event)
            super(event, 'A1')
          end

          def handle
            item('A1_8').set!(@event.options.specific.to_b, :boolean)
            @component.update_global_score
            DukeResponse.new
          end

        end
      end
    end
  end
end
