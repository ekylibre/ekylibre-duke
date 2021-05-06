module Duke
  module Skill
    module Redirections
      class ToBankReconciliationFromSuggestion < Duke::Skill::DukeSingleMatch

        def initialize(event)
          super(user_input: event.user_input)
        end

        # Redirects to bank reconciliation with doc if user click on an account
        def handle
          cash = Cash.find_by_id(@user_input)
          if cash.present?
            Duke::DukeResponse.new(
              redirect: :over,
              sentence: I18n.t('duke.redirections.to_reconciliation_account', id: cash.id, name: cash.name)
            )
          else
            Duke::DukeResponse.new(redirect: :over, sentence: I18n.t('duke.redirections.to_reconcialiation_accounts'))
          end
        end

      end
    end
  end
end
