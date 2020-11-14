module Duke
  class Amounts < Duke::Utils::DukeParsing
    def handle_unpaid_purchases(params)
      I18n.locale = :fra
      Ekylibre::Tenant.switch params['tenant'] do
        c = Backend::Cells::TradeCountsCellsController.new
        sentence = I18n.t("duke.amounts.unpaid_purchases", amount: c.unpaid_purchases_amount.round_l(currency: Preference[:currency]))
        return {:sentence => sentence}
      end 
    end 

    def handle_insurance(params)
      I18n.locale = :fra
      Ekylibre::Tenant.switch params['tenant'] do
        interval_start, interval_end = extract_time_interval(params[:user_input])
        n = Nomen::Account.find(:insurance_expenses)
        amount = 0
        Account.of_usage(n.name).each do |account|
            amount += account.journal_entry_items_calculate(:balance, interval_start, interval_end)
        end
        sentence = I18n.t("duke.amounts.insurance", amount: amount, date: interval_start.strftime("%d/%m/%Y"))
        return {:sentence => sentence}
      end 
    end 

    def handle_active_equipments(params)
      I18n.locale = :fra
      Ekylibre::Tenant.switch params['tenant'] do
        amount = Equipment.all.map { |eq| eq.status }.count(:go)
        sentence = I18n.t("duke.amounts.active_eq", amount: amount)
        return {:sentence => sentence}
      end 
    end 

    def handle_stop_equipments(params)
      I18n.locale = :fra
      Ekylibre::Tenant.switch params['tenant'] do
        amount = Equipment.all.map { |eq| eq.status }.count(:stop)
        sentence = I18n.t("duke.amounts.stopped_eq", amount: amount)
        return {:sentence => sentence}
      end 
    end 

    def handle_problem_equipments(params)
      I18n.locale = :fra
      Ekylibre::Tenant.switch params['tenant'] do
        amount = Equipment.all.map { |eq| eq.status }.count(:caution)
        list = "&#8226 "
        all_caution = Equipment.all.select {|eq| eq.status == :caution}
        list += all_caution.collect(&:name).join("<br>&#8226 ")
        if amount == 0
          sentence = I18n.t("duke.amounts.no_problem_eq")
        elsif amount == 1 
          sentence = I18n.t("duke.amounts.one_problem_eq", name: all_caution.first.name)
        else   
          sentence = I18n.t("duke.amounts.multiple_problem_eq", amount: amount)
        end 
        return {:amount => amount, :sentence => sentence, :equipments => list}
      end 
    end 

    def handle_average_oldness(params)
      I18n.locale = :fra
      Ekylibre::Tenant.switch params['tenant'] do
        lifetimes = Equipment.all.map(&:current_life)
        amount = lifetimes.inject(0) {|sum, x| sum + x.to_f/365}/lifetimes.count
        sentence = I18n.t("duke.amounts.average_oldness", amount: amount.to_i)
        return {:sentence => sentence }
      end 
    end 
  end 
end