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
      {label: label,
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

  end 
end 