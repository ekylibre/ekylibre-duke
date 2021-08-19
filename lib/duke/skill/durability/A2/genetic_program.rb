module Duke
  module Skill
    module Durability
      module A2
        class GeneticProgram < Durability::IdeaArticle

          def initialize(event)
            super(event, 'A2')
          end

          def handle
            item('A2_1').set!(@event.user_input.to_b, :boolean)
            @component.update_global_score
            DukeResponse.new
          end

        end
      end
    end
  end
end
