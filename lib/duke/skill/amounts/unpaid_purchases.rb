module Duke
  module Skill
    module Interventions
      class UnpaidPurchases

        def initialize(event)
          controller = Backend::Cells::TradeCountsCellsController.new
          amount = controller.unpaid_purchases_amount.round_l(currency: Preference[:currency])
          @sentence = I18n.t("duke.amounts.unpaid_purchases", amount: amount)
        end 

        def handle(event)
          DukeResponse.new(sentence: @sentence)
        end
      
      end
    end
  end
end