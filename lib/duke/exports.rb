module Duke
  class Exports
    include Duke::BaseDuke
  
    # Common Method params : {@param [String] user_input, @param [String] user_id, @param [String] session_id}

    # Finds Tool, and launches PrinterJob
    def handle_export_tool_costs(params)
      dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], equipments: Duke::DukeMatchingArray.new)
      dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:equipments, :date))
      return {status: :no_tool, sentence: I18n.t("duke.exports.no_tool_found")} if dukeArt.equipments.empty?
      ToolCostExportJob.perform_later(equipment_ids: [dukeArt.equipments.max.key], campaign_ids: Campaign.current.ids, user: User.find_by(email: params[:user_id]), duke_id: params[:session_id])
      return {status: :started, sentence: I18n.t("duke.exports.tool_export_started" , tool: dukeArt.equipments.max.name)}
    end 

    # @params [String] template_nature
    # @params [String] printer
    def handle_export_balance_sheet(params)
      Duke::DukeBookKeeping.new(user_input: params[:user_input],
                                email: params[:user_id],
                                session_id: params[:session_id],
                                yParam: params[:financial_year]).balance_sheet_redirect(params[:printer], params[:template_nature])
    end 
    
    # Starts fec_export
    def handle_fec_export params 
      Duke::DukeBookKeeping.new(user_input: params[:user_input],
                                email: params[:user_id],
                                session_id: params[:session_id],
                                yParam: params[:financial_year]).fec_redirect(params[:fec_format])
    end 

    # @params [String] template_nature
    # @params [String] printer
    def handle_balance_sheet_financial_year(params)
      begin # Start Export if user clicked fY-btn
        PrinterJob.perform_later(params[:printer], template: DocumentTemplate.find_by_nature(params[:template_nature]), financial_year: FinancialYear.find_by_id(params[:user_input].to_i), perform_as: User.find_by(email: params[:user_id]), duke_id: params[:session_id])
        return {redirect: :started, sentence: I18n.t("duke.exports.#{params[:template_nature]}_started", year: FinancialYear.find_by_id(params[:user_input].to_i).code)}
      rescue 
        return {redirect: :failed}
      end 
    end 

    # Start Tracability Export for a specific activity
    def handle_export_activity_traca(params)
      # WIP : Can't Cherrypick correct activity by it's cultivation_variety_name, must think of another way
      dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], activity_variety: Duke::DukeMatchingArray.new)
      dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:activity_variety, :date))
      return {status: :no_cultivation, sentence: I18n.t("duke.exports.no_var_found")} if dukeArt.activity_variety.empty? 
      max_activity = dukeArt.activity_variety.max
      InterventionExportJob.perform_later(activity_id: max_activity.key, campaign_ids: Activity.find_by(id:max_activity.key).campaigns.pluck(:id), user: User.find_by(email: params[:user_id]), duke_id: params[:session_id])
      return {status: :started, sentence: I18n.t("duke.exports.activity_export_started" , activity: max_activity[:name])}
    end 

    # Disambiguate Activity & starts traçability export
    def handle_activity_disambiguation(params)
      begin 
        max_activity = Activity.find_by(id: params[:user_input].to_i)
        InterventionExportJob.perform_later(activity_id: max_activity[:key], campaign_ids: max_activity.campaigns.pluck(:id), user: User.find_by(email: params[:user_id]), duke_id: params[:session_id])
        return {status: :started, sentence: I18n.t("duke.exports.activity_export_started" , activity: max_activity[:name])}
      rescue Exception
        return {}
      end 
    end 

  end 
end