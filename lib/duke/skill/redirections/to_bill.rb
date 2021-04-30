module Duke
  module Skill
    module Redirections
      class ToBill < Duke::Skill::DukeSingleMatch
        using Duke::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input)
          @entity = Duke::DukeMatchingArray.new
          extract_best(:entity)
          @event = event
        end 

        def handle
          ## modify params purchase_type word to options.sss
          filter = sale_filter(@event.options.specific)
          if @entity.blank?
            Duke::DukeResponse.new(sentence: sentence: I18n.t("duke.redirections.to_#{filter}_bills"))
          else
            Duke::DukeResponse.new(sentence: I18n.t("duke.redirections.to_#{filter}_specific_bills" , entity: @entity.name))
          end
        end
        
      end
    end
  end
end