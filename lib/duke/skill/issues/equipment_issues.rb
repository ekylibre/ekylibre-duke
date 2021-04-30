module Duke
  module Skill
    module Issues
      class EquipmentIssues < Duke::Skill::DukeArticle
        using Duke::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input)
          @cultivablezones = Duke::DukeMatchingArray.new
          @equipments = Duke::DukeMatchingArray.new
          @event = event
        end 

        def handle
          # modify params[:nature] in o
          extract_user_specifics(duke_json: duke_json(:cultivablezones, :equipments, :date))
          if @equipments.empty?
            Duke::DukeResponse.new(redirect: :no, sentence: I18n.t("duke.issues.no_tool_found"))
          else
            url = "/backend/issues/new?target_id=#{)equipments.max.key}"
            # Adding description
            url += "&description=#{params[:user_input].gsub(" ", "+")}&target_type=Equipment"
            # Adding nature 
            url += "&nature=#{@event.options.specific}" unless @event.options.specific.nil?
            if (cz = @cultivablezones.max).present? 
              coords = CultivableZone.find_by(id: cz.key).shape_centroid
              # Adding coordonates
              link += "&lat=#{coords.first}&lon=#{coords.last}"
            end
          end
          Duke::DukeResponse.new(redirect: yes, sentence: I18n.t("duke.issues.found_tool", tool: @equipments.max.name, url: url))
        end

        
      end
    end
  end
end