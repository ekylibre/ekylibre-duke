module Duke
  module Skill
    module Interventions
      class Insurance < Duke::Skill::DukeArticle
        using Duke::DukeRefinements

        def initialize(event)
          super(event)
        end 

        def handle(event)
          started_at, stopped_at = extract_time_interval
          n = Onoma::Account.find(:insurance_expenses)
          amount = 0
          Account.of_usage(n.name).each do |account|
              amount += account.journal_entry_items_calculate(:balance, started_at, stopped_at)
          end
          sentence = I18n.t("duke.amounts.insurance", amount: amount, date: started_at.strftime("%d/%m/%Y"))
          DukeResponse.new(sentence: sentence)
        end
      
      end
    end
  end
end