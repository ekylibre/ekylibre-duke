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
          Duke::DukeSingleMatch.new(user_input: params[:user_input],
            email: params[:user_id],
            session_id: params[:session_id],
            tool: Duke::DukeMatchingArray.new).tool_costs_redirect
        end

        private
        
      end
    end
  end
end