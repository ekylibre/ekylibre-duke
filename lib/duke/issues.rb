module Duke
  class Issues < Duke::Utils::DukeParsing
    def handle_equipment_issues(params)
      # Redirect User to issue declaration of a specific tool
      # params : user_input -> What the user said 
      #          nature     -> IBM potential match for a issue_nature_type
      user_input = clear_string(params[:user_input])
      parsed = {cultivablezones: [],
                equipments: [],
                date: Time.now}
      extract_user_specifics(user_input, parsed, 0.82)
      # If we don't recognize an equipment, we return that we didn't understand the equipment
      if parsed[:equipments].empty? 
        sentence = I18n.t("duke.issues.no_tool_found")
        return {found: :no, sentence: sentence}
      else 
        # Defining which parsed equipment matched the best by distance
        max_equipment = parsed[:equipments].max_by{|eq| eq[:distance]}
        max_cz = parsed[:cultivablezones].max_by{|cz| cz[:distance]}
        # Creating redirection url
        link = "/backend/issues/new?target_id=#{max_equipment[:key]}&description=#{params[:user_input].gsub(" ", "+")}&target_type=Equipment"
        # Adding issue nature if exists
        unless params[:nature].nil?
          link += "&nature=#{params[:nature]}"
        end 
        # Adding cz coordinates if exists
        unless max_cz.nil?
          coords = CultivableZone.find_by(id: max_cz[:key]).shape_centroid
          link += "&lat=#{coords.first}&lon=#{coords.last}"
        end
        # Returning sentence and link
        sentence =  I18n.t("duke.issues.found_tool" , tool: max_equipment[:name])
        return {found: :yes, sentence: sentence, link: link}
      end 
    end 

  end 
end