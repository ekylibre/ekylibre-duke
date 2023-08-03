module Duke
  module Skill
    module Durability
      module A4
        class BushEdge < Durability::IdeaArticle
          using Duke::Utils::DukeRefinements
          include Duke::Utils::BaseDuke

          def initialize(event)
            super(event, 'A4')
          end

          def handle
            sth_val = @event.options.number.to_f
            item('A4_17').set!(sth_val, :float)
            @component.update_global_score
            DukeResponse.new
          end

        end
      end
    end
  end
end