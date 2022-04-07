module Duke
  module Skill
    module TimeLogs
      class SaveTimeLog < Duke::Skill::DukeTimeLog

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
          @warnings = []
        end

        # Look for specific item to be added to intervention
        # options specific: what we're looking for (tool || target || input || doer)
        def handle
          error = validate_working_periods
          if error.nil?
            find_workers.each do |worker|
              @working_periods.each do |wp|
                if Worker.at(wp[:started_at].to_time).include? worker
                  worker.time_logs.create!(started_at: wp[:started_at].to_time, stopped_at: wp[:stopped_at].to_time)
                else
                  @warnings.push(:worker_not_created)
                end
              end
            end
            if @warnings.empty?
              Duke::DukeResponse.new(sentence: I18n.t('duke.time_logs.saved'))
            elsif @warnings.include?(:worker_not_created)
              Duke::DukeResponse.new(sentence: I18n.t('duke.time_logs.saved_with_warnings'))
            elsif @warnings.include?(:finishing_in_future)
              Duke::DukeResponse.new(sentence: I18n.t('duke.time_logs.saved_with_future_warnings'))
            end
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
            if worked_time > 14 || @working_periods.any?{|wp| wp[:started_at].to_time > Time.now}
              return I18n.t('duke.time_logs.impossible')
            end

            @working_periods.each do |wp|
              if wp[:stopped_at].to_time > Time.now
                wp[:stopped_at] = Time.now
                @warnings.push(:finishing_in_future)
              end
            end
            nil
          end

      end
    end
  end
end
