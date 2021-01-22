module Duke
  class Redirections < Duke::Models::DukeArticle
    def handle_to_activity(params)
      # Not done correctly since DukeParsing Update on activities for interventions 
      # params : user_input -> What the user said
      user_input = clear_string(params[:user_input])
      parsed = {activity_variety: []}
      extract_user_specifics(user_input, parsed, 0.82)
      if parsed[:activity_variety].empty? 
        return {found: :no, sentence: I18n.t("duke.redirections.no_activity")}
      else 
        max_variety = parsed[:activity_variety].max_by{|act| act[:distance]}
        iterator = Activity.of_cultivation_variety(Activity.find_by_id(max_variety[:key]).cultivation_variety)
        if iterator.size > 1 
          options = dynamic_options(I18n.t("duke.redirections.which_activity", variety: max_variety[:name]), iterator.map{|act| optJsonify(act[:name], act[:id].to_s)})
          return {found: :multiple, optional: options}
        else 
          sentence = I18n.t("duke.redirections.activity", variety: max_variety[:name])
          return {found: :yes, sentence: sentence, key: max_variety[:key]}
        end 
      end 
    end 

    def handle_which_activity(params)
      begin 
        act = Activity.find_by_id(params[:user_input].to_i)
        return {found: :yes, sentence: I18n.t("duke.redirections.activity", variety: act.cultivation_variety_name), key: act.id}
      rescue 
        return {found: :no, sentence: I18n.t("duke.redirections.no_activity")}
      end 
    end 

    def handle_to_tool(params)
      # Redirect to Tool 
      # params : user_input -> What the user said
      user_input = clear_string(params[:user_input])
      parsed = {equipments: [],
                date: Time.now}
      extract_user_specifics(user_input, parsed, 0.82)
      if parsed[:equipments].empty? 
        sentence = I18n.t("duke.redirections.not_finding")
        return {found: :no, sentence: sentence}
      else 
        max_matcher = parsed[:equipments].max_by{|eq| eq[:distance]}
        sentence =  I18n.t("duke.redirections.found_tool" , tool: max_matcher[:name])
        return {found: :yes, sentence: sentence, key: max_matcher[:key]}
      end 
    end 

    def handle_to_bill(params)
      # Redirect to bill 
      # params : user_input    -> What the user said 
      #          purchase_type -> unpaid or all 
      user_input = clear_string(params[:user_input])
      purchase_type = (:all if params[:purchase_type].nil?)|| :unpaid
      parsed = {entities: [],
                date: Time.now}
      extract_user_specifics(user_input, parsed, 0.82)
      if parsed[:entities].empty? 
        sentence = I18n.t("duke.redirections.to_#{purchase_type}_bills")
        return {sentence: sentence}
      else 
        max_matcher = parsed[:entities].max_by{|eq| eq[:distance]}
        sentence =  I18n.t("duke.redirections.to_#{purchase_type}_specific_bills" , entity: max_matcher[:name])
        return {sentence: sentence}
      end 
    end 

    def handle_to_sale(params) 
      # Redirect to bill 
      # params : user_input    -> What the user said 
      #          purchase_type -> unpaid or all 
      user_input = clear_string(params[:user_input])
      sale_type = (:all if params[:sale_type].nil?)|| :unpaid
      parsed = {entities: [],
                date: Time.now}
      extract_user_specifics(user_input, parsed, 0.82)
      if parsed[:entities].empty? 
        sentence = I18n.t("duke.redirections.to_#{sale_type}_sales")
        return {sentence: sentence}
      else 
        max_matcher = parsed[:entities].max_by{|eq| eq[:distance]}
        sentence =  I18n.t("duke.redirections.to_#{sale_type}_specific_sales" , entity: max_matcher[:name])
        return {sentence: sentence}
      end 
    end 

  end 
end