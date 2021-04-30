module Duke
  module Skill
    module Redirections
      class AccoutingExchange < Duke::Skill::DukeSingleMatch
        using Duke::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input)
          @financial_year = Duke::DukeMatchingArray.new
          extract_best(:financial_year)
        end 

        def handle
          ## modify @financialyear : options.specific
          year_from_id(@event.options.specific)
          if @financial_year.nil?
            w_fy
          elsif FinancialYear.find_by_id(@financial_year[:key]).exchanges.any?{|exc| exc.opened?}
            {redirect: :already_open, sentence: I18n.t("duke.exports.exchange_already_opened", fy: @financial_year[:name], id: @financial_year[:key])}
          elsif Journal.where("nature = 'various'").empty? 
            {redirect: :create_journal, sentence: I18n.t("duke.exports.need_journal_creation")}
          elsif FinancialYear.find_by_id(@financial_year[:key]).accountant.nil?
            {redirect: :add_accountant, sentence: I18n.t("duke.exports.need_fy_accountant", id: @financial_year[:key])}
          elsif Journal.where("nature = 'various'").none?{|jr|jr.accountant == FinancialYear.find_by_id(@financial_year[:key]).accountant}
            {redirect: :modify_accountant, fy: @financial_year[:key], sentence: I18n.t("duke.exports.unconcording_accountants", accountant: FinancialYear.find_by_id(@financial_year[:key]).accountant.full_name)}
          else
            {redirect: :done, sentence: I18n.t("duke.exports.create_exchange", id: @financial_year[:key])}
          end
        end
        
      end
    end
  end
end