module Duke
  module Skill
    module Durability
      class IdeaArticle

        def initialize(event, idea_id)
          @event = event
          @idea_diagnostic = IdeaDiagnostic.find_by_id(event.parsed)
          @idea_diagnostic_item = @idea_diagnostic.idea_diagnostic_items.find_by(idea_id: idea_id)
          @campaign = @idea_diagnostic.campaign
          @component = "Idea::Components::#{idea_id}".constantize.new(diagnostic_id: @idea_diagnostic.id)
        end

        private

          def item(idea_item_value_id)
            @idea_diagnostic_item.idea_diagnostic_item_values.find_by(name: idea_item_value_id)
          end

      end
    end
  end
end
