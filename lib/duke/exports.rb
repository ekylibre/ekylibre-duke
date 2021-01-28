module Duke
  class Exports < Duke::Models::DukeArticle
    
    def handle_export_tool_costs(params)
      dukeArt = Duke::Models::DukeArticle.new(user_input: params[:user_input])
      user_input = clear_string(params[:user_input])
      parsed = {equipments: [],
                date: Time.now}
      extract_user_specifics(user_input, parsed, 0.82)
      if parsed[:equipments].empty? 
        sentence = I18n.t("duke.exports.no_tool_found")
        return {status: :no_tool, sentence: sentence}
      else 
        max_equipment = parsed[:equipments].max_by{|eq| eq[:distance]}
        ToolCostExportJob.perform_later(equipment_ids: [max_equipment[:key]], campaign_ids: Campaign.current.ids, user: User.find_by(email: params[:user_id]), duke_id: params[:session_id])
        sentence =  I18n.t("duke.exports.tool_export_started" , tool: max_equipment[:name])
        return {status: :started, sentence: sentence}
      end 
    end 

    def handle_export_balance_sheet(params)
      user_input = clear_string(params[:user_input])
      parsed = {financial_year: [],
                date: Time.now}
      extract_user_specifics(user_input, parsed, 0.70)
      if parsed[:financial_year].empty? and FinancialYear.all.length > 1
        sentence = I18n.t("duke.exports.which_financial_year")
        dynamic_options = []
        FinancialYear.all.each do |finYear| 
          dynamic_options.push(optJsonify(finYear.code, finYear.id.to_s))
        end 
        return {redirect: :ask_financialyear, options: dynamic_options(sentence, dynamic_options)}
      else 
        if parsed[:financial_year].empty?
          max_year = {key: FinancialYear.first.id, name: FinancialYear.first.code}
        else 
          max_year = parsed[:financial_year].max_by{|yr| yr[:distance]}
        end 
        sentence = I18n.t("duke.exports.#{params[:template_nature]}_started", year: max_year[:name])
        PrinterJob.perform_later(params[:printer], template: DocumentTemplate.find_by_nature(params[:template_nature]), financial_year: FinancialYear.find_by_id(max_year[:key]), perform_as: User.find_by(email: params[:user_id]), duke_id: params[:session_id])
        return {redirect: :started, sentence: sentence}
      end 
    end 

    def handle_balance_sheet_financial_year(params)
      begin 
        PrinterJob.perform_later(params[:printer], template: DocumentTemplate.find_by_nature(params[:template_nature]), financial_year: FinancialYear.find_by_id(params[:user_input].to_i), perform_as: User.find_by(email: params[:user_id]), duke_id: params[:session_id])
        return {redirect: :started, sentence: I18n.t("duke.exports.balance_sheet_started", year: FinancialYear.find_by_id(params[:user_input].to_i).code)}
      rescue 
        return {redirect: :failed}
      end 
    end 

    def handle_export_activity_traca(params)
      # WIP : Can't Cherrypick correct activity by it's cultivation_variety_name, must think of another way
      user_input = clear_string(params[:user_input])
      parsed = {activity_variety: [],
                date: Time.now}
      extract_user_specifics(user_input, parsed, 0.82)
      if parsed[:activity_variety].empty? 
        sentence = I18n.t("duke.exports.no_var_found")
        return {status: :no_cultivation, sentence: sentence}
      else 
        max_activity = parsed[:activity_variety].max_by{|eq| eq[:distance]}
        #type_activities = Activity.all.where("cultivation_variety = #{Activity.find_by(id: max_activity[:id]).cultivation_variety})")
        #year = params[:year]
        InterventionExportJob.perform_later(activity_id: max_activity[:key], campaign_ids: Activity.find_by(id:max_activity[:key]).campaigns.pluck(:id), user: User.find_by(email: params[:user_id]), duke_id: params[:session_id])
        sentence =  I18n.t("duke.exports.activity_export_started" , activity: max_activity[:name])
        return {status: :started, sentence: sentence}
      end  
    end 

    def handle_activity_disambiguation(params)
      # WIP : Can't Cherrypick correct activity by it's cultivation_variety_name, must think of another way
      if is_number?(params[:user_input])
        max_activity = Activity.find_by(id: params[:user_input].to_i)
        InterventionExportJob.perform_later(activity_id: max_activity[:key], campaign_ids: max_activity.campaigns.pluck(:id), user: User.find_by(email: params[:user_id]), duke_id: params[:session_id])
        sentence =  I18n.t("duke.exports.activity_export_started" , activity: max_activity[:name])
        return {status: :started, sentence: sentence}
      else  
        return
      end 
    end 

  end 
end