module Duke
  module Skill
    module Redirections
      class ToFinancialYear < Duke::Skill::DukeSingleMatch

        def initialize(event)
          super(user_input: event.user_input)
          @financial_year = Duke::DukeMatchingArray.new
          extract_best(:financial_year)
        end

        # Redirects to financial years, with doc or a specific financial year if specified
        def handle
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
