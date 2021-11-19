(function (D, $) {

  class WebchatInterface{

    constructor() {
      this.$container = $('#bottom_left');
      this.$duke_input = this.$container.find('#duke-input');
      this.$bottom = this.$container.find('.input-flex');
      this.$msg_container = this.$container.find('.msg_container_base');
      this.$minimize =  this.$container.find('.minus-link');
      this.$btn_mic =  this.$container.find('#btn-mic');
      this.$btn_send = this.$container.find('#btn-send');
      this.$btn_chat = $('.btn-chat');
      this.isMobile = D.DukeUtils.isMobile;
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
        D.webchat.stt.trigger();
      });
  
      this.$btn_send.on("click", () => { // Send msg & stop STT
        this.output_sent();
        D.webchat.send_msg();
        if (D.webchat.stt.inUse) {
          D.webchat.stt.stop();
        }
      });
  
      this.$btn_chat.on("click", () => { // Display the chat 
        this.$btn_chat.hide().css("z-index", "-10");
        this.$container.css("z-index", "999999").show();
        if (!this.isMobile) {
          this.$duke_input.focus();
        }
        this.add_content()
      });
  
      this.$minimize.on("click", () => { // Minimize the chat
        this.$container.hide().css("z-index", "-10");
        this.$btn_chat.css("z-index", "999999").show();
      });
  
      this.$duke_input.each(function() { // Auto-Resize textArea
        this.setAttribute('style', 'height:' + this.scrollHeight + 'px;overflow-y:hidden;');
      }).on('input', function() {
        this.style.height = 'auto';
        D.webchat_interface.$msg_container.css('height', D.webchat_interface.$container.height() - this.scrollHeight - 45);
        this.style.height = this.scrollHeight + 'px';
        D.webchat_interface.scrollDown();
      });
  
      this.$duke_input.keydown((e) => {  // If enter key pressed, send_msg
        if (e.which === 13) {
          if (this.$duke_input.val()) {
            this.output_sent();
            D.webchat.send_msg();
          }
          return false;
        }
      });
        
      window.onresize = (() => { // Resize msg container on window resize
        this.$msg_container.css('height', this.$container.height() - this.$bottom.height() - 45);
      });
    }
    

    /**
     * Integrate Received Message to Webchat & Show chat if hidden
     * @param {CableMsg} data - IBM responseMsg
     */
    onMsg(data) {
      if (this.$btn_chat.is(":visible")){
        this.$btn_chat.css("z-index", "-10").hide()
        this.$container.css("z-index", "999999").show();
      }
      else if (this.$container.is(":hidden")){
        this.$btn_chat.css("z-index", "999999").show()
      }
      this.integrate_received(data.message);
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
     * Creates DukeMEssage from Cable ws & display it
     * @param {CableMsg} data 
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
     * Cable Instanciation to persist Duke on page change
     */
    persist_duke() {
      this.$container.css("z-index", "999999").show();
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

  }
  D.WebchatInterface = WebchatInterface;
})(window.Duke = window.Duke || {}, jQuery);