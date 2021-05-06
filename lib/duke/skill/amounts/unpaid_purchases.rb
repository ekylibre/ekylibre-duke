module Duke
  module Skill
    module Amounts
      class UnpaidPurchases

        def initialize(event); end

        # Obtain amount of unpaid purchases
        def handle
          # controller = Backend::Cells::TradeCountsCellsController.new
          # amount = controller.unpaid_purchases_amount.round_l(currency: Preference[:currency])
          #  Private method, needs reword on ekyviti
          amount = '2943 $'
          @sentence = I18n.t('duke.amounts.unpaid_purchases', amount: amount)
          DukeResponse.new(sentence: @sentence)
        end

      end
    end
  end
end
