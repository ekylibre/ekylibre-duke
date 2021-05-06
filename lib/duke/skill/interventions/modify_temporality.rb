module Duke
  module Skill
    module Interventions
      class ModifyTemporality < Duke::Skill::DukeIntervention

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end

        # Modify date and duration
        # Keeps duration if only date is changed and opposite
        # Keeps hour if only day is changed
        def handle
          tmp_int = Duke::Skill::DukeIntervention.new(procedure: @procedure,  date: @date, user_input: @event.user_input)
          tmp_int.extract_date_and_duration
          join_temporality(tmp_int)
          to_ibm
        end

        private

          # @param [DukeIntervention] int : previous DukeIntervention
          def join_temporality(int)
            self.update_description(int.description)
            if int.working_periods.size > 1 && int.duration.present?
              @working_periods = int.working_periods
              return
            elsif (int.date.to_date == @date.to_date || int.date.to_date != @date.to_date && int.date.to_date == Time.now.to_date)
              @date = @date.to_time.change(hour: int.date.hour, min: int.date.min) if int.not_current_time?
            elsif int.date.to_date != Time.now.to_date
              @date = @date.to_time.change(year: int.date.year, month: int.date.month, day: int.date.day)
              @date = @date.to_time.change(hour: int.date.hour, min: int.date.min) if int.not_current_time?
            end
            @duration = int.duration if int.duration.present? && (@duration.nil? || @duration.eql?(60) || !int.duration.eql?(60))
            working_periods_attributes
          end

      end
    end
  end
end
