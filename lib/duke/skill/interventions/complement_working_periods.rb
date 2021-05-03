module Duke
  module Skill
    module Interventions
      class ComplementWorkingPeriods < Duke::Skill::DukeIntervention
        using Duke::Utils::DukeRefinements

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end

        # Looks for working periods & adds them in concording with previous ones
        def handle
          tmp_int = Duke::Skill::DukeIntervention.new(procedure: @procedure,  date: @date, user_input: @event.user_input.duke_clear)
          tmp_int.extract_wp_from_interval
          add_working_interval(tmp_int.working_periods)
          to_ibm
        end

        private

          # @param [Array] periods : parsed Working_periods
          def add_working_interval(periods)
            if periods.nil?
              return
            else
              periods.each do |period|
                @working_periods.push(period) if @working_periods.none?{ |wp|
                  period[:started_at].between?(wp[:started_at],
                                               wp[:stopped_at]) || period[:stopped_at].between?(wp[:started_at], wp[:stopped_at])
                }
              end
            end
          end

      end
    end
  end
end
