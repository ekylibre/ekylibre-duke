module Duke
  class Exports < Duke::Utils::DukeParsing
    def handle_export_tool_costs(params)
      I18n.locale = :fra
      user_input = clear_string(params[:user_input])
      parsed = {:equipments => [],
                :date => Time.now}
      extract_user_specifics(user_input, parsed, 0.82)
      if parsed[:equipments].empty? 
        sentence = I18n.t("duke.exports.no_tool_found")
        return {:status => :no_tool, :sentence => sentence}
      else 
        max_equipment = parsed[:equipments].max_by{|eq| eq[:distance]}
        ToolCostExportJob.perform_later(equipment_ids: [max_equipment[:key]], campaign_ids: Campaign.current.ids, user: User.find_by(email: params[:user_id]), duke_id: params[:session_id])
        sentence =  I18n.t("duke.exports.tool_export_started" , tool: max_equipment[:name])
        return {:status => :started, :sentence => sentence}
      end 
    end 

    def handle_export_activity_traca(params)
      # WIP : Can't Cherrypick correct activity by it's cultivation_variety_name, must think of another way
      I18n.locale = :fra
      user_input = clear_string(params[:user_input])
      parsed = {:activity_variety => [],
                :date => Time.now}
      extract_user_specifics(user_input, parsed, 0.82)
      if parsed[:activity_variety].empty? 
        sentence = I18n.t("duke.exports.no_var_found")
        return {:status => :no_cultivation, :sentence => sentence}
      else 
        max_activity = parsed[:activity_variety].max_by{|eq| eq[:distance]}
        #type_activities = Activity.all.where("cultivation_variety = #{Activity.find_by(id: max_activity[:id]).cultivation_variety})")
        #year = params[:year]
        InterventionExportJob.perform_later(activity_id: max_activity[:key], campaign_ids: Activity.find_by(id:max_activity[:key]).campaigns.pluck(:id), user: User.find_by(email: params[:user_id]), duke_id: params[:session_id])
        sentence =  I18n.t("duke.exports.activity_export_started" , activity: max_activity[:name])
        return {:status => :started, :sentence => sentence}
      end  
    end 

    def handle_activity_disambiguation(params)
      # WIP : Can't Cherrypick correct activity by it's cultivation_variety_name, must think of another way
      I18n.locale = :fra
      if is_number?(params[:user_input])
        max_activity = Activity.find_by(id: params[:user_input].to_i)
        InterventionExportJob.perform_later(activity_id: max_activity[:key], campaign_ids: max_activity.campaigns.pluck(:id), user: User.find_by(email: params[:user_id]), duke_id: params[:session_id])
        sentence =  I18n.t("duke.exports.activity_export_started" , activity: max_activity[:name])
        return {:status => :started, :sentence => sentence}
      else  
        return
      end 
    end 

  end 
end