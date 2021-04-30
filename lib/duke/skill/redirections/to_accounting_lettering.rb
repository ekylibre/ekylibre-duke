module Duke
  module Skill
    module Redirections
      class ToAccountingLettering < Duke::Skill::DukeSingleMatch
        using Duke::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input)
          @account = Duke::DukeMatchingArray.new
          extract_best(:account)
        end 

        def handle
          ## modify params journal word to options.sss
          if @account.blank?
            {sentence: I18n.t("duke.redirections.letterings")}
          else 
            {sentence: I18n.t("duke.redirections.lettering", name: @account.name, key: @account.key)}
          end
        end
        
      end
    end
  end
end