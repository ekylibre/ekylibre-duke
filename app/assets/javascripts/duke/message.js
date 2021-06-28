(function (D, $) {
  class DukeMessage{
        
    constructor(text, options) {
      this.text = text; 
      this.options = options;
    }
    
    /**
     * Display Loading Icon 
     * Output DukeMessage text & options & handle redirection
     */
    display() {
      if ($('#waiting').length == 0) {
        this.loading_message();
      }
      setTimeout(( () => {$('#waiting').remove();
                          this.output_received_text();
                          this.output_received_options();
                          this.redirect();}), 700);
    };

    /**
     * Output DukeMessage text
     */
    output_received_text() {
      if (this.text == ""){
        return;
      }
      var outputed = this.text.replace(D.DukeUtils.redirectionReg,"")
                              .replace(D.DukeUtils.multChoicesReg, "")
                              .replaceAll(D.DukeUtils.base_urlReg, "")
      $('.duke-received:last p:first').css("border-style", "unset");
      D.webchat_interface.$msg_container.append(D.DukeUtils.templates.msg_received(outputed));
      D.webchat_interface.scrollDown();
    };

    /**
     * Output DukeMessage options
     */
    output_received_options() {
      if (this.options && this.options.length > 0) {
        D.webchat_interface.$msg_container.append(D.DukeUtils.templates.opt_container);
        if (D.DukeUtils.multChoicesReg.test(this.text)) {
          this.multiple_options();
        } else {
          if (this.options.length > 7) {
            this.dropdown_options();
          } else {
            this.single_options();
          }
        }
        D.webchat_interface.scrollDown();
      }
    };

    /**
     * Tickboxes for multiple selection options
     */
    multiple_options() {
      $.each(this.options, function(index, op) {
        if (op.hasOwnProperty('global_label')) {
          $('.msg_container.options').last().append(D.DukeUtils.templates.global_label(op.global_label));
        } else {
          $('.msg_container.options').last().append(D.DukeUtils.templates.mult_option(op.value.input.text, op.label));
        }
      });
      $('.msg_container.options').last().append(D.DukeUtils.templates.mult_validate);
    };

    /**
     * Hoverable buttons for Single selection options 
     */
    single_options() {
      $.each(this.options, function(index, op) {
        if (op.hasOwnProperty('source_dialog_node')) {
          var intent = op.value.input.intents.length == 0 ? "none_of_the_above" : op.value.input.intents[0].intent
          return $('.msg_container.options').last().append(D.DukeUtils.templates.suggestion(op, intent));
        } else {
          return $('.msg_container.options').last().append(D.DukeUtils.templates.option(op.value.input.text, op.label));
        }
      });
    };

    /**
     * Dropdown List for more than 7 single options displayed
     */
    dropdown_options() {
      $('.msg_container.options').last().append(D.DukeUtils.templates.dropdown);
      $.each(this.options, function(index, op) {
        $('.duke-select-ul').last().append(D.DukeUtils.templates.dropdown_opt(op.value.input.text, op.label));
      });
    };

    /**
     * Check if Window needs to be relocalized 
     * Checks if history needs to be reset
     */
    redirect() {
      var duke_chat = Array.from(D.webchat_interface.$msg_container.children()).map(msg => msg.outerHTML).join("")
      var redirection = this.text.match(D.DukeUtils.redirectionReg)
      if (redirection) {
        location.href = redirection[2];
        var duke_chat = redirection[1] ? duke_chat : D.DukeUtils.templates.welcome
        if (redirection[1]) {
          sessionStorage.setItem('duke_visible', true);
        }
      }
      sessionStorage.setItem('duke-chat', duke_chat);
      sessionStorage.setItem("duke_stamp", Date.now());
    };

    /**
     * Loads animated icon
     */
    loading_message() {
      D.webchat_interface.$msg_container.append(D.DukeUtils.templates.loadingIcon);
      D.webchat_interface.scrollDown();
    };
  }
  D.DukeMessage = DukeMessage;
})(window.Duke = window.Duke || {}, jQuery);