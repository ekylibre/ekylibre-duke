module Duke
  module Skill
    module Redirections
      class ToBankReconciliation < Duke::Skill::DukeSingleMatch
        using Duke::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input)
          @bank_account = Duke::DukeMatchingArray.new
          extract_best(:bank_account)
        end 

        def handle
          ## modify importtype opt.specific
          if @event.options.specific.present?
            {status: :over, sentence: I18n.t("duke.redirections.to_reconciliation_import", import: @event.options.specific)}
          elsif @bank_account.blank?
            w_account
          else
            {status: :over, sentence: I18n.t("duke.redirections.to_reconciliation_account", id: @bank_account.key, name: @bank_account.name)}
          end
        end

        private

        # Ask user which bank account he want's to select
        def w_account 
          options = dynamic_options(I18n.t("duke.redirections.which_reconciliation_account"), Cash.all.map{|cash| optJsonify(cash.name, cash.id.to_s)})
          {status: :ask, options: options} 
        end 
        
      end
    end
  end
end