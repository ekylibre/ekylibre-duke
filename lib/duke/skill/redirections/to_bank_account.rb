module Duke
  module Skill
    module Redirections
      class ToBankAccount < Duke::Skill::DukeSingleMatch
        using Duke::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input)
          @bank_account = Duke::DukeMatchingArray.new
          extract_best(:bank_account)
        end 

        def handle
          if @bank_account.blank?
            return {sentence: I18n.t("duke.redirections.to_bank_accounts")} 
          else
            return {sentence: I18n.t("duke.redirections.to_bank_account", name: @bank_account.name, id: @bank_account.key)}
          end
        end
        
      end
    end
  end
end