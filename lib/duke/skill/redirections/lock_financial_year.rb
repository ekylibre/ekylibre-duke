module Duke
  module Skill
    module Redirections
      class LockFinancialYear < Duke::Skill::DukeSingleMatch
        using Duke::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input)
          @financial_year = Duke::DukeMatchingArray.new
          extract_best(:financial_year)
          @event = event
        end 

        def handle
          ## modify params finany to spe
          year_from_id(@event.options.specific)
          if @financial_year.nil?
            w_fy 
          elsif FinancialYear.find_by_id(@financial_year[:key]).state.eql?("locked")
            Duke::DukeResponse.new(
              redirect: :alreadyclosed,
              sentence: I18n.t("duke.exports.locked", code: @financial_year[:name], id: @financial_year[:key])
            )
          else
            Duke::DukeResponse.new(
              redirect: :closed,
              sentence: I18n.t("duke.exports.to_lock", code: @financial_year[:name], id: @financial_year[:key])
            )
          end
        end
        
      end
    end
  end
end