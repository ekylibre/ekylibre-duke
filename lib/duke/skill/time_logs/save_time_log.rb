module Duke
  module Skill
    module TimeLogs
      class SaveTimeLog < Duke::Skill::DukeTimeLog

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end

        # Look for specific item to be added to intervention
        # options specific: what we're looking for (tool || target || input || doer)
        def handle
          error = validate_working_periods
          if error.nil?
            find_workers.each do |worker|
              @working_periods.each do |wp|
                worker.time_logs.create!(started_at: wp[:started_at].to_time, stopped_at: wp[:stopped_at].to_time)
              end
            end
            Duke::DukeResponse.new(sentence: I18n.t('duke.time_logs.saved'))
          else
            Duke::DukeResponse.new(sentence: error)
          end
        end

        private

          def find_workers
            @working_entity.map do |wk|
              Product.find_by_id(wk[:key]).is_a?(Worker) ? Product.find(wk[:key]) : WorkerGroup.find(wk[:key]).items.map(&:worker)
            end.flatten.uniq
          end

          def validate_working_periods
            worked_time = @working_periods.sum do |wp|
              (wp[:stopped_at].to_time - wp[:started_at].to_time) / 1.hours
            end
            if worked_time > 14 || @working_periods.any?{|wp| wp[:stopped_at].to_time > Time.now}
              return I18n.t('duke.time_logs.impossible')
            end
          end

      end
    end
  end
end
