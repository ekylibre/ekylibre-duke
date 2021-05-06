module Duke
  module Skill
    module Redirections
      class ToAccountsPlan < Duke::Skill::DukeSingleMatch

        def initialize(event)
          super(user_input: event.user_input)
          @event = event
        end

        # Redirects to accounting plans with doc, with optional states
        def handle
          if @event.options.specific.present?
            Duke::DukeResponse.new(sentence: I18n.t('duke.redirections.to_account_plan', id: @event.options.specific.delete('^0-9')))
          else
            Duke::DukeResponse.new(sentence: I18n.t('duke.redirections.to_account_plans'))
          end
        end

      end
    end
  end
end
