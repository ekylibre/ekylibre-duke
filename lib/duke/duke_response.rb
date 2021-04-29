module Duke 
  class DukeResponse 

    def initialize(redirect: nil, parsed: nil, sentence: nil, options: nil, moreable: nil, modifiable: nil, user_input: nil)
      @redirect = redirect
      @parsed = parsed
      @sentence = sentence
      @options = options
      @moreable = moreable
      @modifiable = modifiable
    end

  end 
end