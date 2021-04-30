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
          url += ("&state%5B%5D=#{event.options.specific}" if event.options.specific.present?)||"state%5B%5D=draft&state%5B%5D=validated&state%5B%5D=sent" 
          url += ("&period=#{@financial_year.started_on.strftime("%Y-%m-%d")}_#{@financial_year.stopped_on.strftime("%Y-%m-%d")}" if @financial_year.present?)||"&period=all"
          if @financial_year.present?
            {sentence: I18n.t("duke.redirections.to_tax_declaration_period",id: @financial_year.code, url: url)}
          else
            {sentence: I18n.t("duke.redirections.to_tax_declaration", url: url)}
          end
        end
        
      end
    end
  end
end