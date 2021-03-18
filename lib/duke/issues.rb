module Duke
  class Issues
    include Duke::BaseDuke

    # Create an issue on a tool, if tool is found. has optional issue_nature, search for cultivableZone
    # @params [String] user_input 
    # @params [String] nature : Match (optional) for a issue_nature_type
    def handle_equipment_issues(params)
      dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], cultivablezones: Duke::DukeMatchingArray.new, equipments: Duke::DukeMatchingArray.new)
      dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:cultivablezones, :equipments, :date))
      return {found: :no, sentence: I18n.t("duke.issues.no_tool_found")} if dukeArt.equipments.empty? 
      link = "/backend/issues/new?target_id=#{dukeArt.equipments.max.key}&description=#{params[:user_input].gsub(" ", "+")}&target_type=Equipment" # Creating redirection url
      link += "&nature=#{params[:nature]}" unless params[:nature].nil? # Adding issue nature if exists
      unless (max_cz = dukeArt.cultivablezones.max).nil?
        coords = CultivableZone.find_by(id: max_cz.key).shape_centroid
        link += "&lat=#{coords.first}&lon=#{coords.last}" # Adding cz coordinates if exists
      end
      return {found: :yes, sentence: I18n.t("duke.issues.found_tool" , tool: dukeArt.equipments.max.name), link: link}
    end 

  end 
end