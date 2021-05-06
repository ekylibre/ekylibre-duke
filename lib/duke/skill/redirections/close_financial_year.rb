module Duke
  module Skill
    module Redirections
      class CloseFinancialYear < Duke::Skill::DukeSingleMatch

        def initialize(event)
          super(user_input: event.user_input)
          @financial_year = Duke::DukeMatchingArray.new
          extract_best(:financial_year)
          @event = event
        end

        # Redirects to a financial year closure with doc, or to correct steps if everything isn't set correctly
        def handle
          year_from_id(@event.options.specific)
          if @financial_year.nil?
            w_fy
          elsif FinancialYear.find_by_id(@financial_year[:key]).closed?
            Duke::DukeResponse.new(
              redirect: :alreadyclosed,
              sentence: I18n.t('duke.exports.closed', code: @financial_year[:name], id: @financial_year[:key])
            )
          else
            Duke::DukeResponse.new(
              redirect: :closed,
              sentence: I18n.t('duke.exports.to_close', code: @financial_year[:name], id: @financial_year[:key])
            )
          end
        end

      end
    end
  end
end
