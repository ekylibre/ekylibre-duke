module Duke
  module Skill
    module Interventions
      class ProblemEquipments

        def handle(event)
          amount = Equipment.all.map(&:status).count(:caution)
          cautions = Equipment.all.select{|eq| eq.status == :caution}
          list = '&#8226 ' + cautions.map(&:name).join('<br>&#8226 ')
          sentence =  if amount == 0
                        I18n.t('duke.amounts.no_problem_eq')
                      elsif amount == 1
                        I18n.t('duke.amounts.one_problem_eq', name: cautions.first.name)
                      else
                        I18n.t('duke.amounts.multiple_problem_eq', amount: amount)
                      end
          return { amount: amount, sentence: sentence, equipments: list }
        end

      end
    end
  end
end
