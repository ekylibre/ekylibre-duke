module Duke 
  class DukeResponse 

    def initialize(**args)
      args.each do |key, value|
        if permitted_params.include?(key)
          instance_variable_set("@#{key}", value)
        else
          raise ArgumentError
        end
      end
      self.to_json
    end

    private 

    attr_accessor :parsed, :redirect, :options, :optional

    def permitted_params 
      [:parsed, :redirect, :options, :optional]
    end 

  end 
end