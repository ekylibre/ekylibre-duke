module Duke
  module BaseDuke

    def is_number? string
      true if Float(string) rescue false
    end
          
    # Creates a Json for an option
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
    def dynamic_options(sentence, options, description = "")
      optJson = {} 
      optJson[:description] = description
      optJson[:response_type] = "option"
      optJson[:title] = sentence
      optJson[:options] = options
      return [optJson]
    end 

    def dynamic_text(sentence)
      optJson = {} 
      optJson[:response_type] = "text"
      optJson[:text] = sentence
      return [optJson]
    end 

    def clear_string(fstr=@user_input)
      # Remove useless elements from user sentence
      useless_dic = [/\bnum(e|é)ro\b/, /n ?°/,/(le|la|les)/, /(#|-|_|\\)/]
      deburr_dic = {"é"=>"e"}
      useless_dic.each{|rgx| fstr.matchdel(rgx)}
      str = fstr.gsub(/\s+/, " ").strip.downcase.split(" | ").first
      return (I18n.transliterate(str) unless str.nil?)||" "
    end


  end 
end 