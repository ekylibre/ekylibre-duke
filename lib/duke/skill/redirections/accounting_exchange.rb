module Duke
  module Skill
    module Redirections
      class AccountingExchange < Duke::Skill::DukeSingleMatch

        def initialize(event)
          super(user_input: event.user_input)
          @financial_year = Duke::DukeMatchingArray.new
          extract_best(:financial_year)
          @event = event
        end

        # Redirects to an accounting exchange with doc, or to correct steps if everything isn't set correctly
        def handle
          year_from_id(@event.options.specific)
          if @financial_year.nil?
            w_fy
          elsif FinancialYear.find_by_id(@financial_year[:key]).exchanges.any?(&:opened?)
            Duke::DukeResponse.new(
              redirect: :already_open,
              sentence: I18n.t('duke.exports.exchange_already_opened', fy: @financial_year[:name], id: @financial_year[:key])
            )
          elsif Journal.where("nature = 'various'").empty?
            Duke::DukeResponse.new(
              redirect: :create_journal,
              sentence: I18n.t('duke.exports.need_journal_creation')
            )
          elsif FinancialYear.find_by_id(@financial_year[:key]).accountant.nil?
            Duke::DukeResponse.new(
              redirect: :add_accountant,
              sentence: I18n.t('duke.exports.need_fy_accountant', id: @financial_year[:key])
            )
          elsif Journal.where("nature = 'various'").none?{ |j| j.accountant == FinancialYear.find_by_id(@financial_year[:key]).accountant}
            accountant = FinancialYear.find_by_id(@financial_year[:key]).accountant.full_name
            Duke::DukeResponse.new(
              redirect: :modify_accountant,
              sentence: I18n.t('duke.exports.unconcording_accountants', accountant: accountant)
            )
          else
            Duke::DukeResponse.new(redirect: :done, sentence: I18n.t('duke.exports.create_exchange', id: @financial_year[:key]))
          end
        end

      end
    end
  end
end
