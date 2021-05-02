(function (D, $) {

  class DukeWebchat{

    constructor(container, btn_chat) {
      this.$container = container;
      this.$duke_input = this.$container.find('#duke-input');
      this.$bottom = this.$container.find('.input-flex');
      this.$msg_container = this.$container.find('.msg_container_base');
      this.$minimize =  this.$container.find('.minus-link');
      this.$btn_mic =  this.$container.find('#btn-mic');
      this.$btn_send = this.$container.find('#btn-send');
      this.$btn_chat = btn_chat;
      this.isMobile = D.DukeUtils.isMobile;
      this.init();
    };

    /**
     * Get Azure|Pusher Api details & creates handlers
     */
    init() {
      $.ajax('/duke_api_details', {
        type: 'get',
        dataType: 'json',
        success: ((data) => {this.pusher = new D.DukePusherHandler(data.pusher_key);
                            this.stt = new D.DukeSTTHandler(data.azure_key, data.azure_region);
                            if (sessionStorage.getItem('duke-chat')) {
                              this.display();
                            } else {
                              this.create_session(this.msg_callback);
                            };})
      });
      this.bind_events();
    };

    bind_events() {
      this.$duke_input.focusin(() => {  // On focus, color borders
        this.$btn_mic.css('border-color', $('#top_bar').css('background-color'));
      });
  
      this.$duke_input.focusout(() => { // Out focus, uncolor borders
        this.$btn_mic.css('border-color', 'lightgray');
      });
  
      this.$duke_input.keyup((e) => { // On keyPress, check send-btn enabling
        if (this.$duke_input.val() === "") {
          this.$btn_send.toggleClass("disabled-send", true).toggleClass("send-enabled", false);
        } else {
          this.$btn_send.toggleClass("disabled-send", false).toggleClass("send-enabled", true);
        }
      });
  
      this.$btn_mic.on("click", () => {  // Trigger STT
        this.stt.trigger();
      });
  
      this.$btn_send.on("click", () => { // Send msg & stop STT
        this.output_sent();
        this.send_msg();
        if (this.stt.inUse) {
          this.stt.stop();
        }
      });
  
      this.$btn_chat.on("click", () => { // Display the chat 
        this.$btn_chat.hide().css("z-index", "-10");
        this.$container.css("z-index", "9998").show();
        if (!this.isMobile) {
          this.$duke_input.focus();
        }
        this.add_content()
      });
  
      this.$minimize.on("click", () => { // Minimize the chat
        this.$container.hide().css("z-index", "-10");
        this.$btn_chat.css("z-index", "9997").show();
      });
  
      this.$duke_input.each(function() { // Auto-Resize textArea
        this.setAttribute('style', 'height:' + this.scrollHeight + 'px;overflow-y:hidden;');
      }).on('input', function() {
        this.style.height = 'auto';
        D.webchat.$msg_container.css('height', D.webchat.$container.height() - this.scrollHeight - 45);
        this.style.height = this.scrollHeight + 'px';
        D.webchat.scrollDown();
      });
  
      this.$duke_input.keydown((e) => {  // If enter key pressed, send_msg
        if (e.which === 13) {
          if (this.$duke_input.val()) {
            this.output_sent();
            this.send_msg();
          }
          return false;
        }
      });
        
      window.onresize = (() => { // Resize msg container on window resize
        this.$msg_container.css('height', this.$container.height() - this.$bottom.height() - 45);
      });
    }
    
    /**
     * Display Webchat (closed or open)
     */
    display() {
      if (sessionStorage.duke_visible) {
        this.pusher.instanciate(this.persist_duke);
      } else {
        this.pusher.instanciate(this.display_btn_chat);
      }
    };

    is_active() {
      if (Date.now() - parseInt(sessionStorage.duke_stamp) > D.DukeUtils.session_inactivity) {
        this.$msg_container.append(D.DukeUtils.templates.session_expired);
        this.new_active_session(this.msg_callback);
        return false 
      } else {
        return true
      }
    };

    /**
     * AJAX call to create IBM-WA session
     * Stores Assistant ID, SessionId & creates Pusher connection
     */
    create_session(callback) {
      $.ajax('/duke_create_session', {
        type: 'post',
        dataType: 'json',
      success: ((data) => { this.empty_container();
                            sessionStorage.setItem('duke_id', data.session_id);
                            sessionStorage.setItem('assistant_id', data.assistant_id);
                            this.pusher.instanciate(callback);})
      });
    };

    /**
     * Get Welcoming Message by sending empty string on Pusher instanciation
     */
    msg_callback() {
      setTimeout(( () => this.send_msg("")), 1000);
    };

    /**
     * Integrate Received Message to Webchat & Show chat if hidden
     * @param {PusherMsg} data - IBM responseMsg
     */
    onMsg(data) {
      if (this.$btn_chat.is(":visible")){
        this.$btn_chat.css("z-index", "-10").hide()
        this.$container.css("z-index", "9998").show();
      }
      else if (this.$container.is(":hidden")){
        this.$btn_chat.css("z-index", "9997").show()
      }
      this.integrate_received(data.message);
    };

    /**
     * Send Msg to IBM, does not display it
     * @param {String} msg - Sent string (optional: default value = textArea's val)
     * @param {String} user_intent - Intent user want's to trigger (optional)
     */
    send_msg(msg = this.$duke_input.val().replace(/\n/g, "") , user_intent = undefined) {
      this.reset_textarea();
      this.clear_textarea();
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
     * Disables Buttons on previous messages
     * Display sent message inside webchat
     * @param {String} msg - msg to display
     */
    output_sent(msg = this.$duke_input.val().replace(/\n/g, "")) {
      this.disable_buttons();
      if (msg) {
        this.$msg_container.append(D.DukeUtils.templates.msg_sent(msg));
        this.scrollDown();
      }
    };

    /**
     * Remove Dropdowns & Tickboxes validation buttons & disable basic-buttons
     */
    disable_buttons() {
      $(".duke-select-wrap").last().parent().remove();
      $(".duke-centered").last().remove();
      if (this.$msg_container.children().last().hasClass('options')) {
        $.each(this.$msg_container.children().last().children(), function(index, option) {
          $(option).prop("disabled", true);
          if (!$(option).hasClass("duke-selected")) {
            return $(option).toggleClass("hover-fill duke-disabled");
          }
        });
      }
    };

    /**
     * Creates DukeMEssage from Pusher ws & display it
     * @param {PusherMsg} data 
     */
    integrate_received(data) {
      $.each(data, function(idx, value) {
        var text = value.response_type == "text" ? value.text : value.title;
        var options = value.response_type == "option" ? value.options : value.suggestions;
        new D.DukeMessage(text, options).display();
      });
    };

    /**
     * Enable|Disable buttonClick on send-btn given TextArea's value
     */
    enable_send() {
    if (this.$duke_input.val() == "")
      this.$btn_send.toggleClass("disabled-send", true).toggleClass("send-enabled",false)
    else
      this.$btn_send.toggleClass("disabled-send", false).toggleClass("send-enabled",true)
    return
    };

    /**
     * Recreate webchat Content
     */
    add_content() {
      this.$msg_container.children().remove();
      this.$msg_container.append(sessionStorage.getItem('duke-chat'));
      this.scrollDown();
    };

    /**
     * Pusher Instanciation to persist Duke on page change
     */
    persist_duke() {
      this.$container.css("z-index", "9998").show();
      this.add_content()
      sessionStorage.removeItem('duke_visible');
    };

    /**
     * Remove TextArea content
     */
    clear_textarea() {
      this.$btn_send.toggleClass("disabled-send", true).toggleClass("send-enabled", false);
      this.$duke_input.val("");
    };

    /**
     * Reset TextArea size to regular
     */
    reset_textarea() {
      this.$duke_input.css('height', '60px');
      this.$msg_container.css('height', this.$container.height() - this.$bottom.height() - 45);
    };

    /**
     * Scroll message container to last message
     */
    scrollDown() {
      this.$msg_container.scrollTop(this.$msg_container[0].scrollHeight);
    };

    empty_container() {
      this.$msg_container.children().remove();
    };

    display_btn_chat() {
      this.$btn_chat.show();
    }

    new_active_session(callback) {
      this.scrollDown();
      this.create_session(callback);
      sessionStorage.setItem("duke_stamp", Date.now());
    };
  }
  D.DukeWebchat = DukeWebchat;
})(window.Duke = window.Duke || {}, jQuery);