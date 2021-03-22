module Duke
  class Exports
    include Duke::BaseDuke
  
    # Common Method params : {@param [String] user_input, @param [String] user_id, @param [String] session_id}

    # Start tool costs export job
    def handle_export_tool_costs params 
      Duke::DukeSingleMatch.new(user_input: params[:user_input],
                                email: params[:user_id],
                                session_id: params[:session_id],
                                tool: Duke::DukeMatchingArray.new).tool_costs_redirect
    end 

    # @params [String] template_nature
    # @params [String] printer
    def handle_export_balance_sheet(params)
      Duke::DukeSingleMatch.new(user_input: params[:user_input],
                                email: params[:user_id],
                                session_id: params[:session_id]).balance_sheet_redirect(params[:financial_year], params[:printer], params[:template_nature])
    end 
    
    # Starts fec_export
    # @param [String] fec_format - Fec format
    def handle_fec_export params 
      Duke::DukeSingleMatch.new(user_input: params[:user_input],
                                email: params[:user_id],
                                session_id: params[:session_id]).fec_redirect(params[:financial_year], params[:fec_format])
    end 

    # Start Tracability Export for a specific activity
    def handle_export_activity_traca(params)
      Duke::DukeSingleMatch.new(user_input: params[:user_input],
                                email: params[:user_id],
                                session_id: params[:session_id],
                                activity_variety: Duke::DukeMatchingArray.new).activity_traca_redirect
    end

  end 
end