module Duke
  module Skill
    module Redirections
      class ToProductionCost < Duke::Skill::DukeSingleMatch

        def initialize(event)
          super(user_input: event.user_input)
          @campaign = Duke::DukeMatchingArray.new
          extract_best(:campaign)
          @event = event
        end

        # Redirects to production_cost dashboard with the campaign if exist
        def handle
          if @campaign.present?
            Duke::DukeResponse.new(
              sentence: I18n.t('duke.redirections.to_production_cost_campaign', harvest_year: Campaign.find(@campaign.key).harvest_year)
            )
          else
            Duke::DukeResponse.new(
              sentence: I18n.t('duke.redirections.to_production_cost_default')
            )
          end
        end

      end
    end
  end
end
