module Duke
  module Skill
    module Durability
      module A2
        class IntensiveSth < Durability::IdeaArticle

          def initialize(event)
            super(event, 'A2')
          end

          def handle
            if numbers = @event.user_input.match(Duke::Utils::Regex.up_to_four_digits_float)
              item('A2_17').set!(numbers[0].gsub(',', '.').gsub(' ', '').to_f, :float)
              @component.update_global_score
            end
            DukeResponse.new
          end

        end
      end
    end
  end
end
