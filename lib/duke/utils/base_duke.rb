module Duke
  module BaseDuke

    # @param [String] string
    # @return [Boolean] is_number? 
    def number? string
      true if Float(string) rescue false
    end
          
    # Creates a Json for an option
    # @param [String] label - Displayed btn text
    # @param [String] text - Sent value on btn.click
    def optJsonify(label, text=label)
      {
        label: label,
        value: {
          input: {
            text: text
          }
        }
      }
    end 

    # Creates a dynamic options array that can be displayed as options to ibm
    # @param [String] sentence - Options title 
    # @param [Array] options - Array of optJsonified options 
    # @param [String] description 
    def dynamic_options(sentence, options, description = "")
      optJson = {} 
      optJson[:description] = description
      optJson[:response_type] = "option"
      optJson[:title] = sentence
      optJson[:options] = options
      return [optJson]
    end 

    # Create a dynamic text array that can be display as text by ibm
    # @param [String] sentence - text to be displayed
    def dynamic_text(sentence)
      optJson = {} 
      optJson[:response_type] = "text"
      optJson[:text] = sentence
      return [optJson]
    end 

    # @returns exclusive farming type :vine_farming || :plant_farming if exists
    def exclusive_farming_type
      farming_types = Activity.availables.select("distinct family").map(&:family)
      if (type = farming_types & %w[plant_farming vine_farming]).size.eql?(1) 
        return type.first.to_sym
      end 
    end 

    def btn_click_response?(str)
      str.match(/^(\d{1,5}(\|{3}|\b))*$/).present?
    end

    def btn_click_cancelled? str 
      str.eql?("*cancel*")
    end 

    def btn_click_responses(str)
      str.split(/\|{3}/).map{|num| num.to_i}
    end 

    def procedure_entities
      JSON.parse(File.read(Duke.proc_entities_path)).deep_symbolize_keys
    end 

    # is Tenant ekyagri ?
    def ekyagri? 
      Activity.availables.none? {|act| act.family == :vine_farming}
    end 

    # does Tenant have any vegetal activity ?
    def vegetal? 
      Activity.availables.any? {|act| act.family == :plant_farming}
    end 

    # does Tenant have any animal activity ?
    def animal? 
      Activity.availables.any? {|act| act.family == :animal_farming}
    end 

  end 
end 