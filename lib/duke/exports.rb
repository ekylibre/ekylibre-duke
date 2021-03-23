module Duke
  class Exports
    include Duke::BaseDuke

    # common @params : 
    #   @params [String] user_input 
    #   @params [String] user_id - user.email
    #   @params [String] session_id - duke_id

    # Start tool costs export job
    def handle_export_tool_costs params 
      Duke::DukeSingleMatch.new(user_input: params[:user_input],
                                email: params[:user_id],
                                session_id: params[:session_id],
                                tool: Duke::DukeMatchingArray.new).tool_costs_redirect
    end 


    # Start 'template_nature' export job if financialYear is found, or ask for it.
    # @params [String] template_nature
    # @params [String] printer
    def handle_export_balance_sheet(params)
      Duke::DukeSingleMatch.new(user_input: params[:user_input],
                                email: params[:user_id],
                                session_id: params[:session_id],
                                financial_year: Duke::DukeMatchingArray.new).balance_sheet_redirect(params[:financial_year], params[:printer], params[:template_nature])
    end 

    # Start activity tracability export if we found an activity
    def handle_export_activity_traca(params)
      Duke::DukeSingleMatch.new(user_input: params[:user_input],
                                email: params[:user_id],
                                session_id: params[:session_id],
                                activity_variety: Duke::DukeMatchingArray.new).activity_traca_redirect
    end 

  end 
end