module Duke
  module Skill
    module Redirections
      class ToFixedAssetSale < Duke::Skill::DukeSingleMatch

        def initialize(event)
          super(user_input: event.user_input)
          @fixed_asset = Duke::DukeMatchingArray.new
          extract_best(:fixed_asset)
        end

        # Redirects to fixed_assets, or a specific, with the sale documentation
        def handle
          if @fixed_asset.blank?
            Duke::DukeResponse.new(sentence: I18n.t('duke.redirections.to_immobilisations_sale'))
          else
            Duke::DukeResponse.new(
              sentence: I18n.t('duke.redirections.to_immobilisation_sale', name: @fixed_asset[:name], id: @fixed_asset[:key])
            )
          end
        end

      end
    end
  end
end
