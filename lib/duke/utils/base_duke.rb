module Duke
  module Utils
    module BaseDuke

      # @param [String] string
      # @return [Boolean] is_number?
      def number?(string)
        true if Float(string) rescue false
      end

      # Creates a Json for an option
      # @param [String] label - Displayed btn text
      # @param [String] text - Sent value on btn.click
      def optionify(label, text = label)
        {
          label: label,
          value: {
            input: {
              text: text
            }
          }
        }
      end

      # Creates a dynamic options array that can be displayed as options to ibm
      # @param [String] sentence - Options title
      # @param [Array] options - Array of optJsonified options
      # @param [String] description
      def dynamic_options(sentence, options, description = '')
        json = {}
        json[:description] = description
        json[:response_type] = 'option'
        json[:title] = sentence
        json[:options] = options
        return [json]
      end

      # Create a dynamic text array that can be display as text by ibm
      # @param [String] sentence - text to be displayed
      def dynamic_text(sentence)
        json = {}
        json[:response_type] = 'text'
        json[:text] = sentence
        return [json]
      end

      # @param [String] msg - sentence to be displayed as information
      # @return [String] - Html information div with sentence
      def duke_information_tag(msg)
        "<div class='duke-information'>
          <i style='color: #3340A4;'class='icon icon-help-outline'></i> #{msg}
        </div>"
      end

      # @returns exclusive farming type :vine_farming :plant_farming if exists
      def exclusive_farming_type
        farming_types = Activity.availables.pluck('DISTINCT family')
        if (type = farming_types & %w[plant_farming vine_farming]).size.eql?(1)
          return type.first.to_sym
        end
      end

      def btn_click_response?(str)
        str.match(/^(\d{1,5}(\|{3}|\b))*$/).present?
      end

      def btn_click_cancelled?(str)
        str.eql?('*cancel*')
      end

      def btn_click_responses(str)
        str.split(/\|{3}/).map(&:to_i)
      end

      def procedure_entities
        JSON.parse(File.read(Duke.proc_entities_path)).deep_symbolize_keys
      end

      # does Tenant have any vegetal activity ?
      def vegetal?
        Activity.availables.any? {|act| act.family == :plant_farming}
      end

      # does Tenant have any animal activity ?
      def animal?
        Activity.availables.any? {|act| act.family == :animal_farming}
      end

    end
  end
end
