module Duke
  module Skill
    module Redirections
      class ToTaxDeclaration < Duke::Skill::DukeSingleMatch

        def initialize(event)
          super(user_input: event.user_input)
          @financial_year = Duke::DukeMatchingArray.new
          extract_best(:financial_year)
          @event = event
        end

        # Redirects to tax declarations, state & financial year can be specified
        def handle
          url = '/backend/tax-declarations?utf8=✓&q='
          url +=  if @event.options.specific.present?
                    "&state%5B%5D=#{@event.options.specific}"
                  else
                    'state%5B%5D=draft&state%5B%5D=validated&state%5B%5D=sent'
                  end
          if @financial_year.present?
            year = FinancialYear.find_by_id(@financial_year[:key])
            url += "&period=#{year.started_on.strftime('%Y-%m-%d')}_#{year.stopped_on.strftime('%Y-%m-%d')}"
            Duke::DukeResponse.new(sentence: I18n.t('duke.redirections.to_tax_declaration_period', id: year.code, url: url))
          else
            url += '&period=all'
            Duke::DukeResponse.new(sentence: I18n.t('duke.redirections.to_tax_declaration', url: url))
          end
        end

      end
    end
  end
end
