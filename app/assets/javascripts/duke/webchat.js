(function (D, $) {

  class DukeWebchat{

    constructor() {
      D.webchat_interface = new D.WebchatInterface();
      this.init();
    };

    /**
     * Get Azure Api details & creates handlers
     */
    init() {
      $.ajax('/duke_api_details', {
        type: 'get',
        dataType: 'json',
        success: ((data) => {this.actionCable = new D.DukeActionCableHandler();
                            this.stt = new D.DukeSTTHandler(data.azure_key, data.azure_region);
                            if (sessionStorage.getItem('duke-chat')) {
                              this.display();
                            } else {
                              this.create_session(this.msg_callback);
                            };})
      });
    };
    
    /**
     * Display Webchat (closed or open)
     */
    display() {
      if (sessionStorage.duke_visible) {
        this.actionCable.instanciate(this.persist_duke);
      } else {
        this.actionCable.instanciate(this.display_btn_chat);
      }
    };

    display_btn_chat() {
      D.webchat_interface.display_btn_chat();
    };

    is_active() {
      if (Date.now() - parseInt(sessionStorage.duke_stamp) > D.DukeUtils.session_inactivity) {
        D.webchat_interface.$msg_container.append(D.DukeUtils.templates.session_expired);
        this.new_active_session();
        return false 
      } else {
        return true
      }
    };

    /**
     * AJAX call to create IBM-WA session
     * Stores Assistant ID, SessionId & creates Cable connection
     */
    create_session(callback, intent, msg) {
      $.ajax('/duke_create_session', {
        type: 'post',
        dataType: 'json',
      success: ((data) => { D.webchat_interface.empty_container();
                            sessionStorage.setItem('duke_id', data.session_id);
                            sessionStorage.setItem('assistant_id', data.assistant_id);
                            this.actionCable.instanciate(callback, intent, msg);})
      });
    };

    /**
     * Get Welcoming Message by sending empty string on Cable instanciation
     */
    msg_callback(intent, msg) {
      this.send_msg(msg, intent=intent)
    };

    /**
     * Send Msg to IBM, does not display it
     * @param {String} msg - Sent string (optional: default value = textArea's val)
     * @param {String} user_intent - Intent user want's to trigger (optional)
     */
    send_msg(msg = D.webchat_interface.$duke_input.val().replace(/\n/g, "") , user_intent) {
      D.webchat_interface.reset_textarea();
      D.webchat_interface.clear_textarea();
      if (this.is_active()){
        if (msg.toString().match(D.DukeUtils.cancelationReg)) {
          user_intent = "Exit";
        }
        $.ajax('/duke_send_msg', {
          type: 'post',
          data: {
            "msg": msg,
            "user_intent": user_intent,
            "duke_id": sessionStorage.getItem('duke_id'),
            "assistant_id": sessionStorage.getItem('assistant_id')
          },
          dataType: 'json'
        });
      };
    };

    /**
     * Cable Instanciation to persist Duke on page change
     */
    persist_duke() {
      D.webchat_interface.$container.css("z-index", "9998").show();
      D.webchat_interface.add_content()
      sessionStorage.removeItem('duke_visible');
    };

    new_active_session(intent, msg) {
      D.webchat_interface.scrollDown();
      this.create_session(this.msg_callback, intent, msg);
      sessionStorage.setItem("duke_stamp", Date.now());
    };
  }
  D.DukeWebchat = DukeWebchat;
})(window.Duke = window.Duke || {}, jQuery);