module Duke
  module Skill
    module Redirections
      class Fallback < Duke::Skill::DukeSingleMatch
        using Duke::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input)
          @activity_variety = Duke::DukeMatchingArray.new
          @tool = Duke::DukeMatchingArray.new
          @entity = Duke::DukeMatchingArray.new
          extract_best(:journal)
        end 

        def handle
          best = best_of(:tool, :entity, :activity_variety)
          if best.blank?
            {found: :no, sentence: I18n.t("duke.redirections.no_fallback")}
          else
            {found: :yes, sentence: I18n.t("duke.redirections.#{best[:type]}_fallback", id: best.key, name: best.name)}
          end
        end

        private

        # Return best match across multiple entries, with it's type as an hash entry
        def best_of(*args)
          vals = args.map{|arg| send(arg).merge_h({type: arg}) if send(arg).present?}.compact
          return vals.max_by{|itm| itm.distance}
        end
        
      end
    end
  end
end