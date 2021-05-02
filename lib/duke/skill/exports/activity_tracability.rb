module Duke
  module Skill
    module Exports
      class ActivityTracability < Duke::Skill::DukeSingleMatch
        using Duke::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input, email: event.user_id, session_id: event.session_id)
          @activity_variety = DukeMatchingArray.new
          extract_best(:activity_variety)
        end

        def handle
          if @activity_variety.blank?
            Duke::DukeResponse.new(redirect: :no_cultivation, sentence: I18n.t('duke.exports.no_var_found'))
          else
            InterventionExportJob.perform_later(activity_id:  @activity_variety.key,
                                                campaign_ids:  Activity.find_by(id: @activity_variety.key).campaigns.pluck(:id),
                                                user: User.find_by(email: @email),
                                                duke_id: @session_id)
            sentence = I18n.t('duke.exports.activity_export_started', activity: @activity_variety.name)
            Duke::DukeResponse.new(redirect: :started, sentence: sentence)
          end
        end

      end
    end
  end
end
