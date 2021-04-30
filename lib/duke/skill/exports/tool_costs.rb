module Duke
  module Skill
    module Exports
      class ToolCosts < Duke::Skill::DukeSingleMatch
        using Duke::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input, email: event.user_id, session_id: event.session_id)
          @tool = DukeMatchingArray.new
          extract_best(:tool)
        end 

        def handle
          if @tool.blank?
            {status: :no_tool, sentence: I18n.t("duke.exports.no_tool_found")}
          else
            ToolCostExportJob.perform_later(equipment_ids: [@tool.key], campaign_ids: Campaign.current.ids, user: User.find_by(email: @email, duke_id: @session_id))
            {status: :started, sentence: I18n.t("duke.exports.tool_export_started" , tool: @tool.name)}
          end
        end

        private
        
      end
    end
  end
end