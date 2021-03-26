module Duke
  module Skill
    class Amounts
      include Duke::BaseDuke

      # Common @params : [String] user_input : User Utterance

      # @return [Json] sentence with unpaid purchase amount
      def handle_unpaid_purchases(params)
        c = Backend::Cells::TradeCountsCellsController.new
        sentence = I18n.t("duke.amounts.unpaid_purchases", amount: c.unpaid_purchases_amount.round_l(currency: Preference[:currency]))
        return {sentence: sentence}
      end 

      # @return [Json] sentence with paid insurance for specific period
      def handle_insurance(params)
        dukeArt = Duke::DukeArticle.new(user_input: params[:user_input])
        interval_start, interval_end = dukeArt.extract_time_interval
        n = Onoma::Account.find(:insurance_expenses)
        amount = 0
        Account.of_usage(n.name).each do |account|
            amount += account.journal_entry_items_calculate(:balance, interval_start, interval_end)
        end
        sentence = I18n.t("duke.amounts.insurance", amount: amount, date: interval_start.strftime("%d/%m/%Y"))
        return {sentence: sentence}
      end 

      # @return [Json] sentence with number of active equipments
      def handle_active_equipments(params)
        amount = Equipment.all.map { |eq| eq.status }.count(:go)
        sentence = I18n.t("duke.amounts.active_eq", amount: amount)
        return {sentence: sentence}
      end 

      # @return [Json] sentence with number of stopped equipments
      def handle_stop_equipments(params)
        amount = Equipment.all.map { |eq| eq.status }.count(:stop)
        sentence = I18n.t("duke.amounts.stopped_eq", amount: amount)
        return {sentence: sentence}
      end 

      # @return [Json] sentence with number of equipments with issue
      def handle_problem_equipments(params)
        amount = Equipment.all.map { |eq| eq.status }.count(:caution)
        cautions = Equipment.all.select{|eq|eq.status == :caution}
        list = "&#8226 " + cautions.map(&:name).join('<br>&#8226 ')
        sentence =  if amount == 0
                      I18n.t("duke.amounts.no_problem_eq")
                    elsif amount == 1 
                      I18n.t("duke.amounts.one_problem_eq", name: cautions.first.name)
                    else   
                      I18n.t("duke.amounts.multiple_problem_eq", amount: amount)
                    end 
        return {amount: amount, sentence: sentence, equipments: list}
      end 

      # @return [Json] sentence with average oldness of tools
      def handle_average_oldness(params)
        lifetimes = Equipment.all.map(&:current_life)
        amount = lifetimes.inject(0) {|sum, x| sum + x.to_f/365}/lifetimes.count
        sentence = I18n.t("duke.amounts.average_oldness", amount: amount.to_i)
        return {sentence: sentence }
      end 
    end 
  end
end