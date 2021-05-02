module Duke
  module Skill
    module Amounts
      class AverageOldness

        def initialize(event); end

        def handle
          lifetimes = Equipment.all.map(&:current_life)
          amount = lifetimes.inject(0) {|sum, x| sum + x.to_f/365} / lifetimes.count
          sentence = I18n.t('duke.amounts.average_oldness', amount: amount.to_i)
          DukeResponse.new(sentence: sentence)
        end

      end
    end
  end
end
