module Duke
  module Skill
    module Redirections
      class ToAccountsPlan < Duke::Skill::DukeSingleMatch
        using Duke::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input)
          @event = event
        end 

        def handle
          ## modify params account_id 
          if @event.options.specific.present? 
            {sentence: I18n.t("duke.redirections.to_account_plan",id: @event.options.specific.delete("^0-9"))}
          else 
            {sentence: I18n.t("duke.redirections.to_account_plans")}
          end
        end
        
      end
    end
  end
end