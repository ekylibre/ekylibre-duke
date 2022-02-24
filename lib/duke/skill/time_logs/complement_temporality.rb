module Duke
  module Skill
    module TimeLogs
      class ComplementTemporality < Duke::Skill::DukeTimeLog
        using Duke::Utils::DukeRefinements

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
          @user_input = @event.user_input.duke_clear
        end

        # Look for specific item to be added to intervention
        # options specific: what we're looking for (tool || target || input || doer)
        def handle
          tmp_int = Duke::Skill::DukeTimeLog.new(date: @date, user_input: @event.user_input)
          tmp_int.extract_date_and_duration
          join_temporality(tmp_int)
          to_ibm
        end

        private

          def redirect
            return :save_time, speak_time_log
          end

      end
    end
  end
end
