(function (D, $) {
  ekylibre.onDomReady(function () { // Create Webchat on DomReady, initialize Cable connection & sets Specific handlers bindings
    if (D.webchat){
      D.webchat_interface = new D.WebchatInterface();
      D.webchat_interface.display_btn_chat();
    } else {
      D.webchat = new D.DukeWebchat();
    }
  });

  $(document).on('click', '.duke-default-option', function() { // Display dropdown list
    $(this).parent().toggleClass('active');
    D.webchat_interface.scrollDown();
  });

  $(document).on('click', '.duke-select-ul li', function() {  // Remove dropdown, send msg
    $(this).parents('.msg_container').remove();
    D.webchat_interface.output_sent($(this).html());
    D.webchat.send_msg($(this).data("value"));
  });

  $(document).on('click', '.control--checkbox', function(evt) { // Check tickbox, display Validation btn
    evt.stopPropagation();
    evt.preventDefault();
    $(this).children().last().toggleClass('duke-checked');
    $('.duke-checkbox-validation').show();
  });

  $(document).on('click', '.duke-cancelation', function() { // Send cancelation msg
    D.webchat_interface.output_sent($(this).html());
    D.webchat.send_msg('*cancel*');
  });

  $(document).on('click', '.duke-validation', function() { // Map chosen tickboxes values & send msg
    str = Array.from($('.msg_container.options.general').last().children()).map(opt => $(opt).children().last().hasClass('duke-checked') ? $(opt).data('value') : undefined).filter(Boolean).join("|||")
    D.webchat_interface.output_sent($(this).html());
    D.webchat.send_msg(str);
  });
  
  $(document).on('click', '.duke-message-option, .duke-suggestion', function() { // Send Chosen option value
    target = event.target || event.srcElement;
    $(this).toggleClass("hover-fill duke-selected");
    D.webchat_interface.output_sent(target.innerHTML);
    D.webchat.send_msg($(this).data("value"), $(this).data("intent")); // send Msg with intent( suggestion ? data-intent : undefined)
  });
})(window.Duke = window.Duke || {}, jQuery);