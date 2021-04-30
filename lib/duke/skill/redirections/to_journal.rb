module Duke
  module Skill
    module Redirections
      class ToJournal < Duke::Skill::DukeSingleMatch
        using Duke::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input)
          @journal = Duke::DukeMatchingArray.new
          extract_best(:journal)
        end 

        def handle
          ## modify params journal word to options.sss
          if @journal.blank? 
            {sentence: I18n.t("duke.redirections.journals")} 
          else 
            {sentence: I18n.t("duke.redirections.journal", name: @journal.name, key: @journal.key)}
          end
        end

        private
        
      end
    end
  end
end