module Duke
  class Exports
    include Duke::BaseDuke
    
    # @params [String] user_input
    # @params [String] user_id = user.email
    # @params [String] session_id = duke_id
    # Finds Tool, and launches PrinterJob
    def handle_export_tool_costs(params)
      dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], equipments: Duke::DukeMatchingArray.new)
      dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:equipments, :date))
      return {status: :no_tool, sentence: I18n.t("duke.exports.no_tool_found")} if dukeArt.equipments.empty?
      ToolCostExportJob.perform_later(equipment_ids: [dukeArt.equipments.max.key], campaign_ids: Campaign.current.ids, user: User.find_by(email: params[:user_id]), duke_id: params[:session_id])
      return {status: :started, sentence: I18n.t("duke.exports.tool_export_started" , tool: dukeArt.equipments.max.name)}
    end 

    # @params [String] user_input
    # @params [String] template_nature
    # @params [String] printer
    # @params [Stirng] user_id = user.email
    # @params [String] session_id = duke_id
    def handle_export_balance_sheet(params)
      dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], financial_year: Duke::DukeMatchingArray.new)
      dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:financial_year, :date), level: 0.72)
      if dukeArt.financial_year.empty? && FinancialYear.all.length > 1
        options = dynamic_options(I18n.t("duke.exports.which_financial_year"), FinancialYear.all.map{|fY| optJsonify(fY.code, fY.id.to_s)})
        return {redirect: :ask_financialyear, options: options}
      else 
        max_year =  if dukeArt.financial_year.empty? 
                      {key: FinancialYear.first.id, name: FinancialYear.first.code}
                    else 
                      dukeArt.financial_year.max
                    end
        sentence = I18n.t("duke.exports.#{params[:template_nature]}_started", year: max_year.name)
        PrinterJob.perform_later(params[:printer], template: DocumentTemplate.find_by_nature(params[:template_nature]), financial_year: FinancialYear.find_by_id(max_year.key), perform_as: User.find_by(email: params[:user_id]), duke_id: params[:session_id])
        return {redirect: :started, sentence: sentence}
      end 
    end 

    # @params [String] user_input
    # @params [String] template_nature
    # @params [String] printer
    # @params [Stirng] user_id = user.email
    # @params [String] session_id = duke_id
    def handle_balance_sheet_financial_year(params)
      begin # If user clicked on a fY code, we launch its export by id
        PrinterJob.perform_later(params[:printer], template: DocumentTemplate.find_by_nature(params[:template_nature]), financial_year: FinancialYear.find_by_id(params[:user_input].to_i), perform_as: User.find_by(email: params[:user_id]), duke_id: params[:session_id])
        return {redirect: :started, sentence: I18n.t("duke.exports.#{params[:template_nature]}_started", year: FinancialYear.find_by_id(params[:user_input].to_i).code)}
      rescue 
        return {redirect: :failed}
      end 
    end 

    # @params [String] user_input
    # @params [Stirng] user_id = user.email
    # @params [String] session_id = duke_id
    def handle_export_activity_traca(params)
      # WIP : Can't Cherrypick correct activity by it's cultivation_variety_name, must think of another way
      dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], activity_variety: Duke::DukeMatchingArray.new)
      dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:activity_variety, :date))
      return {status: :no_cultivation, sentence: I18n.t("duke.exports.no_var_found")} if dukeArt.activity_variety.empty? 
      max_activity = dukeArt.activity_variety.max
      InterventionExportJob.perform_later(activity_id: max_activity.key, campaign_ids: Activity.find_by(id:max_activity.key).campaigns.pluck(:id), user: User.find_by(email: params[:user_id]), duke_id: params[:session_id])
      return {status: :started, sentence: I18n.t("duke.exports.activity_export_started" , activity: max_activity[:name])}
    end 

    # @params [String] user_input
    # @params [Stirng] user_id = user.email
    # @params [String] session_id = duke_id
    def handle_activity_disambiguation(params)
      begin 
        max_activity = Activity.find_by(id: params[:user_input].to_i)
        InterventionExportJob.perform_later(activity_id: max_activity[:key], campaign_ids: max_activity.campaigns.pluck(:id), user: User.find_by(email: params[:user_id]), duke_id: params[:session_id])
        return {status: :started, sentence: I18n.t("duke.exports.activity_export_started" , activity: max_activity[:name])}
      rescue
        return {}
      end 
    end 

    # @params [String] user_input
    # @params [String] user_id = user.email
    # @params [String] session_id = duke_id
    # @params [String] financial_year - optional Financial Year Id if clicked by user
    def handle_accounting_exchange params 
      if params[:financial_year].present? && is_number?(params[:financial_year]) && FinancialYear.all.collect(&:id).include?(params[:financial_year].to_i)
        max_year = {key: params[:financial_year].to_i, name: FinancialYear.find_by_id(params[:financial_year].to_i).code}
      elsif FinancialYear.all.empty? 
        return {redirect: :createFinancialYear, sentence: I18n.t("duke.exports.need_financial_year_creation")}
      else 
        dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], financial_year: Duke::DukeMatchingArray.new)
        dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:financial_year, :date), level: 0.72)
        if dukeArt.financial_year.present? 
          max_year = dukeArt.financial_year.max
        elsif FinancialYear.all.length == 1
          max_year = {key: FinancialYear.first.id, name: FinancialYear.first.code}
        else  
          options = dynamic_options(I18n.t("duke.exports.which_financial_year_exchange"), FinancialYear.all.map{|fY| optJsonify(fY.code, fY.id.to_s)})
          return {redirect: :ask_financialyear, options: options}
        end
      end 
      # After Finding correct Financial Year, we check other requirements for accounting exchange
      return {redirect: :already_open, sentence: I18n.t("duke.exports.exchange_already_opened", fy: max_year[:name], id: max_year[:key])} if FinancialYear.find_by_id(max_year[:key]).exchanges.any?{|exc| exc.opened?} 
      return {redirect: :create_journal, sentence: I18n.t("duke.exports.need_journal_creation")} if Journal.where("nature = 'various'").empty? 
      return {redirect: :add_accountant, sentence: I18n.t("duke.exports.need_fy_accountant", id: max_year[:key])} if FinancialYear.find_by_id(max_year[:key]).accountant.nil? 
      return {redirect: :modify_accountant, fy: max_year[:key], sentence: I18n.t("duke.exports.unconcording_accountants", accountant: FinancialYear.find_by_id(max_year.key).accountant.full_name)} if Journal.where("nature = 'various'").none?{|jr|jr.accountant == FinancialYear.find_by_id(max_year.key).accountant}
      return {redirect: :done, sentence: I18n.t("duke.exports.create_exchange", id: max_year[:key])}
    end 

  end 
end