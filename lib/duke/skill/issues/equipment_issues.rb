module Duke
  module Skill
    module Issues
      class EquipmentIssues < Duke::Skill::DukeArticle
        using Duke::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input)
          @cultivablezones = Duke::DukeMatchingArray.new
          @equipments = Duke::DukeMatchingArray.new
        end 

        def handle
          extract_user_specifics(duke_json: duke_json(:cultivablezones, :equipments, :date))
          return {found: :no, sentence: I18n.t("duke.issues.no_tool_found")} if dukeArt.equipments.empty? 
          link = "/backend/issues/new?target_id=#{dukeArt.equipments.max.key}&description=#{params[:user_input].gsub(" ", "+")}&target_type=Equipment" # Creating redirection url
          link += "&nature=#{params[:nature]}" unless params[:nature].nil? # Adding issue nature if exists
          unless (max_cz = dukeArt.cultivablezones.max).nil?
            coords = CultivableZone.find_by(id: max_cz.key).shape_centroid
            link += "&lat=#{coords.first}&lon=#{coords.last}" # Adding cz coordinates if exists
          end
          return {found: :yes, sentence: I18n.t("duke.issues.found_tool" , tool: dukeArt.equipments.max.name), link: link}
        end

        private
        
      end
    end
  end
end