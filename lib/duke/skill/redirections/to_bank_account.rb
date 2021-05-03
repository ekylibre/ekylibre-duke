module Duke
  module Skill
    module Redirections
      class ToBankAccount < Duke::Skill::DukeSingleMatch

        def initialize(event)
          super(user_input: event.user_input)
          @bank_account = Duke::DukeMatchingArray.new
          extract_best(:bank_account)
        end

        # Redirects to a bank accounts, or all bank accounts
        def handle
          if @bank_account.blank?
            Duke::DukeResponse.new(sentence: I18n.t('duke.redirections.to_bank_accounts'))
          else
            Duke::DukeResponse.new(sentence: I18n.t('duke.redirections.to_bank_account', name: @bank_account.name, id: @bank_account.key))
          end
        end

      end
    end
  end
end
