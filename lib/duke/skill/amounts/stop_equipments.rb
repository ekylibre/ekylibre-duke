module Duke
  module Skill
    module Amounts
      class StopEquipments

        def initialize(event); end

        # Obtain number of stopped equipments
        def handle
          amount = Equipment.all.map(&:status).count(:stop)
          sentence = I18n.t('duke.amounts.stopped_eq', amount: amount)
          DukeResponse.new(sentence: sentence)
        end

      end
    end
  end
end
