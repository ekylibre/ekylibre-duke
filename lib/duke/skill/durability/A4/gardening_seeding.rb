module Duke
  module Skill
    module Durability
      module A4
        class GardeningSeeding < Durability::IdeaArticle
          using Duke::Utils::DukeRefinements
          include Duke::Utils::BaseDuke

          def initialize(event)
            super(event, 'A4')
          end

          def handle
            item('A4_09').set!(@event.options.specific.to_b, :boolean)
            @component.update_global_score
            DukeResponse.new
          end

        end
      end
    end
  end
end