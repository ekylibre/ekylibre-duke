module Duke
  module Skill
    module Redirections
      class WhichActivity < Duke::Skill::DukeSingleMatch
        using Duke::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input)
          @activity_variety = Duke::DukeMatchingArray.new
          extract_best(:activity_variety)
        end 

        def handle
          act = Activity.find_by_id(@user_input.to_i)
          if act.present?
            Duke::DukeResponse.new(
              redirect: :yes,
              sentence: I18n.t("duke.redirections.activity", variety: act.cultivation_variety_name),
              parsed: act.id
            )
          else
            Duke::DukeResponse.new(redirect: :no, sentence: I18n.t("duke.redirections.no_activity"))
          end
        end
        
      end
    end
  end
end