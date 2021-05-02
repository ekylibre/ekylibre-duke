module Duke
  module Skill
    module Exports
      class BalanceSheet < Duke::Skill::DukeSingleMatch

        def initialize(event)
          super(user_input: event.user_input, email: event.user_id, session_id: event.session_id)
          @financial_year = DukeMatchingArray.new
          extract_best(:financial_year)
          @event = event
        end

        def handle
          year_from_id(@event.options.specific)
          if @financial_year.nil?
            w_fy
          else
            PrinterJob.perform_later(@event.options.printer,
                                     template: DocumentTemplate.find_by_nature(@event.options.template),
                                     financial_year: FinancialYear.find_by_id(@financial_year[:key]),
                                     perform_as: User.find_by(email: @email),
                                     duke_id: @session_id)
            sentence = I18n.t("duke.exports.#{@event.options.template}_started", year: @financial_year[:name])
            Duke::DukeResponse.new(redirect: :started, sentence: sentence)
          end
        end

      end
    end
  end
end
