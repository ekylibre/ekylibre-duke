module Duke
  class DukeEvent

    attr_reader :tenant, :handler, :user_id, :session_id, :user_input, :options, :parsed

    def initialize(params)
      @tenant = params[:tenant]
      @handler = params[:handler]
      @user_id = params[:user_id]
      @session_id = params[:session_id]
      @user_input = params[:user_input]
      @parsed = params[:parsed]
      @options = params.fetch(:options, {}).symbolize_keys.slice(*options_params).to_struct
    end

    private

      def options_params
        %I[ambiguity_key ambiguity_type procedure specific index quantity number printer template]
      end

  end
end
