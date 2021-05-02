module Duke
  module Skill
    module Interventions
      class ActiveEquipments

        def handle(event)
          amount = Equipment.all.map(&:status).count(:go)
          sentence = I18n.t('duke.amounts.active_eq', amount: amount)
          DukeResponse.new(sentence: sentence)
        end

      end
    end
  end
end
