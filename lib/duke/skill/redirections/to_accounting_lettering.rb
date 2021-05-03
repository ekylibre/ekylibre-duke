module Duke
  module Skill
    module Redirections
      class ToAccountingLettering < Duke::Skill::DukeSingleMatch
        using Duke::Utils::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input.duke_del(event.options.specific))
          @account = Duke::DukeMatchingArray.new
          extract_best(:account)
        end

        # Redirects to accounting lettering with doc, on specific account, or on list view
        def handle
          if @account.blank?
            Duke::DukeResponse.new(sentence: I18n.t('duke.redirections.letterings'))
          else
            Duke::DukeResponse.new(sentence: I18n.t('duke.redirections.lettering', name: @account.name, key: @account.key))
          end
        end

      end
    end
  end
end
