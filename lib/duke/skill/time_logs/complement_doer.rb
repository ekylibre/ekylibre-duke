module Duke
  module Skill
    module TimeLogs
      class ComplementDoer < Duke::Skill::DukeTimeLog

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end

        # Look for specific item to be added to intervention
        # options specific: what we're looking for (tool || target || input || doer)
        def handle
          tmp_time_log = Duke::Skill::DukeTimeLog.new.recover_from_hash(@event.parsed)
          tmp_time_log.working_entity = DukeMatchingArray.new
          tmp_time_log.user_input = @event.user_input
          tmp_time_log.parse_specific_buttons(:working_entity)
          @working_entity = tmp_time_log.working_entity
          to_ibm
        end

        private

          def redirect
            if @working_entity.present?
              return :save_time, speak_time_log
            else
              return :time_log_canceled
            end
          end

      end
    end
  end
end
