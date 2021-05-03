module Duke
  module Skill
    module Amounts
      class ActiveEquipments

        def initialize(event); end

        # Obtain number of active equipments
        def handle
          amount = Equipment.all.map(&:status).count(:go)
          sentence = I18n.t('duke.amounts.active_eq', amount: amount)
          DukeResponse.new(sentence: sentence)
        end

      end
    end
  end
end
