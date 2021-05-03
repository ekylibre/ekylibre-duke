module Duke
  module Skill
    module Redirections
      class ToFixedAsset < Duke::Skill::DukeSingleMatch

        def initialize(event)
          super(user_input: event.user_input)
          @fixed_asset = Duke::DukeMatchingArray.new
          extract_best(:fixed_asset)
          @event = event
        end

        # Redirects to fixed_assets, or a specific by product name
        def handle
          if @fixed_asset.present?
            Duke::DukeResponse.new(
              sentence: I18n.t('duke.redirections.to_fixed_asset_product', name: @fixed_asset.name, id: @fixed_asset.key)
            )
          elsif @event.options.specific.present?
            Duke::DukeResponse.new(sentence: I18n.t('duke.redirections.to_fixed_asset_state', state: @event.options.specific))
          else
            Duke::DukeResponse.new(sentence: I18n.t('duke.redirections.to_all_fixed_assets'))
          end
        end

      end
    end
  end
end
