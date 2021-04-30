module Duke
  module Skill
    module Exports
      class ActivityTracability < Duke::Skill::DukeSingleMatch
        using Duke::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input, email: event.user_id, session_id: event.session_id)
          @activity_variety = DukeMatchingArray.new
          extract_best(:activity_variety)
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