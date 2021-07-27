module Duke
  module Skill
    module Durability
      class Redirect < IdeaArticle

        def initialize(event)
          super(event, event.options.specific)
        end

        def handle
          @component.duke_redirect
        end

      end
    end
  end
end
