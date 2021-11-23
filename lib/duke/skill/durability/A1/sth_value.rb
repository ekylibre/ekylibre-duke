module Duke
  module Skill
    module Durability
      module A1
        class SthValue < Durability::IdeaArticle

          def initialize(event)
            super(event, 'A1')
          end

          def handle
            sth_val = sth_ratio(@event.options.number.to_f)
            item('A1_10').set!(sth_val, :float)
            item('A2_27', 'A2').set!(sth_val, :float)
            @component.update_global_score
            DukeResponse.new
          end

          private

            def sth_ratio(sth)
              # TODO: do it correctly
              12
            end

        end
      end
    end
  end
end
