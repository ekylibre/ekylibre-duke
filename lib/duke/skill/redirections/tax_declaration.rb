module Duke
  module Skill
    module Redirections
      class TaxDeclaration < Duke::Skill::DukeSingleMatch

        def initialize(event)
          super(user_input: event.user_input)
          @financial_year = Duke::DukeMatchingArray.new
          extract_best(:financial_year)
          @event = event
        end

        def handle
          # # modify financial_year: options.specific
          year_from_id(@event.options.specific)
          if FinancialYear.all.none?{|fy| !fy.tax_declaration_mode_none?}
            Duke::DukeResponse.new(sentence: I18n.t('duke.exports.no_tax_declaration'))
          elsif @financial_year.present? && FinancialYear.find_by_id(@financial_year[:key]).tax_declaration_mode_none?
            Duke::DukeResponse.new(sentence: I18n.t('duke.exports.no_tax_on_fy', code: @financial_year[:name], id: @financial_year[:key]))
          elsif @financial_year.blank?
            Duke::DukeResponse.new(sentence: I18n.t('duke.exports.tax_on_no_fy'))
          else
            Duke::DukeResponse.new(sentence: I18n.t('duke.exports.tax_on_fy', code: @financial_year[:name], id: @financial_year[:key]))
          end
        end

      end
    end
  end
end
