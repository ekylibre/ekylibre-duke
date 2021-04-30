module Duke
  module Skill
    module Redirections
      class ToTaxDeclaraton < Duke::Skill::DukeSingleMatch
        using Duke::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input)
          @journal = Duke::DukeMatchingArray.new
          extract_best(:journal)
          @event = event
        end 

        def handle
          ## modify @tax_state = options.specific
          url = "/backend/tax-declarations?utf8=✓&q="
          url +=  if event.options.specific.present?
                    "&state%5B%5D=#{event.options.specific}"
                  else
                    "state%5B%5D=draft&state%5B%5D=validated&state%5B%5D=sent"
                  end 
          if @financial_year.present?
            url += "&period=#{@financial_year.started_on.strftime("%Y-%m-%d")}_#{@financial_year.stopped_on.strftime("%Y-%m-%d")}"
            Duke::DukeResponse.new(sentence: I18n.t("duke.redirections.to_tax_declaration_period", id: @financial_year.code, url: url))
          else
            url += "&period=all"
            Duke::DukeResponse.new(sentence: I18n.t("duke.redirections.to_tax_declaration", url: url))
          end
        end
        
      end
    end
  end
end