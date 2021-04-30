module Duke
  module Skill
    module Redirections
      class ToSale < Duke::Skill::DukeSingleMatch
        using Duke::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input)
          @entity = Duke::DukeMatchingArray.new
          extract_best(:entity)
          @event = event
        end 

        def handle
          ## modify params qale_type : qq word to options.sss
          filter = sale_filter(@event.options.specific)
          if @entity.blank?
            {sentence: I18n.t("duke.redirections.to_#{filter}_sales")}
          else 
            {sentence: I18n.t("duke.redirections.to_#{filter}_specific_sales" , entity: @entity.name)}
          end
        end

      end
    end
  end
end