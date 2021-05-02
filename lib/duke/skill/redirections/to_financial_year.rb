module Duke
  module Skill
    module Redirections
      class ToFinancialYear < Duke::Skill::DukeSingleMatch

        def initialize(event)
          super(user_input: event.user_input)
          @financial_year = Duke::DukeMatchingArray.new
          extract_best(:financial_year)
        end

        def handle
          # # modify params journal word to options.sss
          if @financial_year.blank?
            Duke::DukeResponse.new(sentence: I18n.t('duke.redirections.financial_years'))
          else
            Duke::DukeResponse.new(
              sentence: I18n.t('duke.redirections.financial_year', key: @financial_year.key, name: @financial_year.name)
            )
          end
        end

      end
    end
  end
end
