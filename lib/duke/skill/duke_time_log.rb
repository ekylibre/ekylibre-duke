module Duke
  module Skill
    class DukeTimeLog < DukeArticle
      using Duke::Utils::DukeRefinements
      attr_accessor :working_entity, :working_periods

      def initialize(**args)
        super()
        args.each{|k, v| instance_variable_set("@#{k}", v)}
        @ambiguities = []
        @working_periods = []
      end

      # Extract both date_and duration (Both information can be extract from same string)
      def extract_date_and_duration
        @user_input = @user_input.duke_clear
        input_clone = @user_input.clone
        extract_duration
        extract_date
        extract_wp_from_interval(input_clone)
        unless @working_periods.present?
          if input_clone.match(Duke::Utils::Regex.morning_hour)
            @duration = 60 if @duration.nil?
          elsif input_clone.match(Duke::Utils::Regex.afternoon_hour)
            @date = @date.change(hour: @date.hour+12)
            @duration = 60 if @duration.nil?
          elsif input_clone.match('matin')
            if duration.present?
              working_periods_attributes
              return
            else
              @working_periods =
              [
                {
                  started_at: @date.to_time.change(offset: @offset, hour: 8, min: 0),
                  stopped_at: @date.to_time.change(offset: @offset, hour: 12, min: 0)
                  }
                ]
            end
          elsif input_clone.match(Duke::Utils::Regex.afternoon)
            if @duration.present?
              working_periods_attributes
              return
            else
              @working_periods =
              [
                {
                  started_at: @date.to_time.change(offset: @offset, hour: 14, min: 0),
                  stopped_at: @date.to_time.change(offset: @offset, hour: 17, min: 0)
                  }
                ]
            end
          elsif not_current_time? && @duration.nil? # One hour duration if hour specified but no duration
            @duration = 60
          end
        end
        working_periods_attributes unless @working_periods.present?
      end

      def working_periods_attributes
        if @duration.nil? # Basic working_periods if duration.nil?:true
          @working_periods =
          [
            {
              started_at: @date.to_time.change(offset: @offset) - 1.hour,
              stopped_at: @date.to_time.change(offset: @offset)
            }
          ]
        elsif @duration.is_a?(Integer) # Specific working_periods if a duration was found
          @working_periods =
          [
            {
              started_at: @date.to_time.change(offset: @offset) - @duration.to_i.minutes,
              stopped_at: @date.to_time.change(offset: @offset)
            }
          ]
        end
      end

      private

        def extract_duration
          super()
          if @duration.nil? && min_time = @user_input.matchdel(Duke::Utils::Regex.basic_duration)
            @duration = min_time[1].to_i * 60
            @duration += min_time[3].to_i if min_time[3]
          end
        end

        def speak_duration
          @duration % 60 == 0 ? "#{@duration/60}h" : "#{@duration/60}h#{@duration % 60}"
        end

        def parseable
          [*super(), :working_entity].uniq
        end

        def redirect
          if @ambiguities.present?
            return :ask_ambiguity, nil, @ambiguities.first
          elsif @working_entity.present?
            return :save_time, speak_time_log
          else
            return :ask_doer, nil, worker_options
          end
        end

        def speak_time_log
          sentence = I18n.t('duke.time_logs.ask.save_time_log')
          sentence += "<br>&#8226 #{I18n.t('duke.interventions.doer')} : #{@working_entity.map(&:name).join(', ')}"
          sentence += "<br>&#8226 #{I18n.t('duke.interventions.date')} : #{@date.to_time.strftime('%d/%m/%Y')}"
          wp = @working_periods.sort_by{|wp| wp[:started_at]}
          sentence += "<br>&#8226 #{I18n.t('duke.time_logs.working_periods')} : #{wp.map do |wp|
                                                                                    I18n.t('duke.interventions.working_periods',
                                                                                           start: speak_hour(wp[:started_at]),
                                                                                           ending: speak_hour(wp[:stopped_at]))
                                                                                  end.join(', ')}"
        end

        # @param [String] type : Type of item for which we want to display all suggestions
        # @return [Json] OptJson for Ibm to display clickable buttons with every item & labels
        def worker_options
          items =
            [
              [
                {
                  global_label: 'Équipier(s)'
                },
                Worker.availables(at: @date.to_time)
              ],
              [
                {
                  global_label: "Groupe(s) d'équipiers"
                },
                WorkerGroup.at(@date.to_time)
              ]
            ]
          options = items.flatten.map do |itm| # Turn it to Jsonified options
            checked = itm.respond_to?(:id) && send(:working_entity).any?{|reco| reco.key == itm.id}
            if itm.is_a?(Hash)
              itm
            else
              optionify(checked ? "#{itm.send(:name)}=isChecked" : itm.send(:name), itm.id)
            end
          end
          if options.empty?
            dynamic_text(I18n.t('duke.interventions.ask.no_complement'))
          else
            dynamic_options(I18n.t('duke.interventions.ask.what_complement_doer'), options)
          end
        end

    end
  end
end
