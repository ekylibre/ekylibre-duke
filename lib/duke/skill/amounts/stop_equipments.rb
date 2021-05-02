module Duke
  module Skill
    module Interventions
      class StopEquipments

        def initialize(event); end

        def handle(event)
          amount = Equipment.all.map(&:status).count(:stop)
          sentence = I18n.t('duke.amounts.stopped_eq', amount: amount)
          DukeResponse.new(sentence: sentence)
        end

      end
    end
  end
end
