module Duke 
  class DukeEvent 

    attr_reader :tenant, :handler, :user_id, :user_input, :options, :parsed

    def initialize(params)
      @tenant = params[:tenant]
      @handler = params[:handler]
      @user_id = params[:user_id]
      @user_input = params[:user_input]
      @options = params.fetch(:options, {}).permit(*options_params).to_h.to_struct
      @parsed = params.fetch(:parsed, {}).permit!
    end 

    private 

    def options_params 
      %I[ambiguity_key ambiguity_type procedure specific index quantity]
    end 

  end 
end