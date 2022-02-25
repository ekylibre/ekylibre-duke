module Duke
  module Skill
    module TimeLogs
      class GetComplementDoers < Duke::Skill::DukeTimeLog

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end

        # Returns optionified items of specific type to be displayed to the user
        # options specific: what we'll display (input || doer || tool)
        def handle
          Duke::DukeResponse.new(options: worker_options)
        end

      end
    end
  end
end
