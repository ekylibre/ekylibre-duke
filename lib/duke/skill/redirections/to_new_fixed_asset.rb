module Duke
  module Skill
    module Redirections
      class ToNewFixedAsset < Duke::Skill::DukeSingleMatch
        using Duke::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input)
          @depreciable = Duke::DukeMatchingArray.new
          extract_best(:depreciable)
        end

        def handle
          if @depreciable.blank?
            Duke::DukeResponse.new(redirect: :speak, sentence: I18n.t('duke.redirections.to_undefined_fixed_asset'))
          else
            Duke::DukeResponse.new(
              redirect: :speak,
              sentence: I18n.t('duke.redirections.to_specific_fixed_asset', id: @depreciable.key, name: @depreciable.name)
            )
          end
        end

      end
    end
  end
end
