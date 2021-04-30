module Duke
  module Skill
    module Redirections
      class ToActivity < Duke::Skill::DukeSingleMatch
        using Duke::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input)
          @activity_variety = Duke::DukeMatchingArray.new
          extract_best(:activity_variety)
        end 

        def handle
          if @activity_variety.blank?
            return {found: :no, sentence: I18n.t("duke.redirections.no_activity")} # Return if no activity matched
          elsif (iterator = Activity.of_cultivation_variety(Activity.find_by_id(@activity_variety.key).cultivation_variety)).size > 1
            w_variety(iterator)
          else
            {found: :yes, sentence: I18n.t("duke.redirections.activity", variety: @activity_variety.name), key: @activity_variety.key}
          end
        end

        private

        # Ask user which variety he want's to select
        def w_variety vars
          opts = vars.map{|act| optJsonify(act.name, act.id.to_s)}
          return {found: :multiple, optional: dynamic_options(I18n.t("duke.redirections.which_activity", variety: @activity_variety.name), opts)}
        end 
        
      end
    end
  end
end