module Duke
  class Redirections
    include Duke::BaseDuke

    # Common @params : [String] user_input : User Utterance

    # Redirects to activity, or suggest multiple if cultivation_variety ambiguity
    # @return [Json] found: boolean|multiple, sentence & optional
    def handle_to_activity(params)
      dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], activity_variety: Duke::DukeMatchingArray.new)
      dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:activity_variety, :date))
      return {found: :no, sentence: I18n.t("duke.redirections.no_activity")} if dukeArt.activity_variety.empty? # Return if no activity matched
      max_variety = dukeArt.activity_variety.max
      iterator = Activity.of_cultivation_variety(Activity.find_by_id(max_variety.key).cultivation_variety)
      if iterator.size > 1 # If more than one activity of this variety, ask which
        return {found: :multiple, optional: dynamic_options(I18n.t("duke.redirections.which_activity", variety: max_variety.name), iterator.map{|act| optJsonify(act.name, act.id.to_s)})}
      else # If only one, return
        return {found: :yes, sentence: I18n.t("duke.redirections.activity", variety: max_variety.name), key: max_variety.key}
      end 
    end 

    # Parse btn.click for activity to be redirected to
    # @return [Json] found: boolean, sentence
    def handle_which_activity(params)
      begin # if user_clicked on Activity, user_input is it's id
        act = Activity.find_by_id(params[:user_input].to_i)
        return {found: :yes, sentence: I18n.t("duke.redirections.activity", variety: act.cultivation_variety_name), key: act.id}
      rescue # Return misunderstanding
        return {found: :no, sentence: I18n.t("duke.redirections.no_activity")}
      end 
    end 

    # Redirects to tool 
    def handle_to_tool(params)
      dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], equipments: Duke::DukeMatchingArray.new)
      dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:equipments, :date))
      return {found: :no, sentence: I18n.t("duke.redirections.not_finding")} if dukeArt.equipments.empty?
      return {found: :yes, sentence: I18n.t("duke.redirections.found_tool" , tool: dukeArt.equipments.max.name), key: dukeArt.equipments.max.key}
    end 

    # @param [String] purchase_type : unpaid|nil
    def handle_to_bill(params)
      dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], entities: Duke::DukeMatchingArray.new)
      dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:entities, :date))
      purchase_type = (:all if params[:purchase_type].nil?)|| :unpaid
      return {sentence: I18n.t("duke.redirections.to_#{purchase_type}_bills")} if dukeArt.entities.empty?
      return {sentence: I18n.t("duke.redirections.to_#{purchase_type}_specific_bills" , entity: dukeArt.entities.max.name)}
    end 

    # @param [String] sale_type : unpaid|nil
    def handle_to_sale(params) 
      dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], entities: Duke::DukeMatchingArray.new)
      dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:entities, :date))
      sale_type = (:all if params[:sale_type].nil?)|| :unpaid
      return {sentence: I18n.t("duke.redirections.to_#{sale_type}_sales")} if dukeArt.entities.empty?
      return {sentence: I18n.t("duke.redirections.to_#{sale_type}_specific_sales" , entity: dukeArt.entities.max.name)}
    end 

  end 
end