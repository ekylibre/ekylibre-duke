module Duke
  class Issues < Duke::Utils::DukeParsing
    def handle_equipment_issues(params)
      I18n.locale = :fra
      user_input = clear_string(params[:user_input])
      Ekylibre::Tenant.switch params['tenant'] do
        parsed = {:equipments => [],
                  :date => Time.now}
        extract_user_specifics(user_input, parsed, 0.82)
        if parsed[:equipments].empty? 
          sentence = I18n.t("duke.issues.no_tool_found")
          return {:found => :no, :sentence => sentence}
        else 
          max_equipment = parsed[:equipments].max_by{|eq| eq[:distance]}
          cz_parsed = {:cultivablezones => [],
                       :date => Time.now }
          extract_user_specifics(user_input, cz_parsed, 0.82)
          max_cz = cz_parsed[:cultivablezones].max_by{|eq| eq[:distance]}
          link = "\\backend\\issues\\new?target_id=#{max_equipment[:key]}&description=#{params[:user_input].gsub(" ", "+")}&target_type=Equipment"
          unless params[:nature].nil?
            link += "&nature=#{params[:nature]}"
          end 
          unless max_cz.nil?
            coords = CultivableZone.find_by(id: max_cz[:key]).shape_centroid
            link += "&lat=#{coords.first}&lon=#{coords.last}"
          end
          sentence =  I18n.t("duke.issues.found_tool" , tool: max_equipment[:name])
          return {:found => :yes, :sentence => sentence, :link => link}
        end 
      end 
    end 

  end 
end