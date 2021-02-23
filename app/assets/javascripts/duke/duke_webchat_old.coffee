(($, E) ->
  $.getScript 'https://js.pusher.com/7.0/pusher.min.js'
  $(document).behave "load", "duke[data-current-account]", ->
    webchat = new DukeWebchat($(this).data('current-account'), $(this).data('current-tenant'), $(this).data('pusher-key'))
    recognizer = new DukeSTTGenerator($(this).data('azure-key'), $(this).data('azure-region'))
    webchat.init()
    $('#duke-input').each(->
      @setAttribute 'style', 'height:' + @scrollHeight + 'px;overflow-y:hidden;'
      return
    ).on 'input', ->
      @style.height = 'auto'
      $('.msg_container_base').css('height', $('#bottom_left').height() - @scrollHeight - 45)
      @style.height = @scrollHeight + 'px'
      $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
      return
    # OnKeyPressed inside Duke Textarea -> Enable/Disable send button
    $('#duke-input').keyup (e) ->
      if $("#duke-input").val() == ""
        $('#btn-send').toggleClass("disabled-send", true).toggleClass("send-enabled",false)
      else
        $('#btn-send').toggleClass("disabled-send", false).toggleClass("send-enabled",true)
      return
    # Before sending keyValue to Duke's Textarea -> If PressedKey is enter -> Send Message
    $('#duke-input').keydown (e) ->
      code = if e.keyCode then e.keyCode else e.which
      if code == 13
        if $("#duke-input").val() != ""
          output_sent()
          send_msg()
        return false
    # Adding borders around mic btn on textarea focus
    $('#duke-input').focusin ->
      $('#btn-mic').css('border-color', $('#top_bar').css('background-color'))
    # Removing borders on textarea focusout
    $('#duke-input').focusout ->
      $('#btn-mic').css('border-color', 'lightgray')

  # OnButtonChatClik, we show the chat window, & restore the discussion if any, or show waiting sign until ready
  $(document).on 'click', '.btn-chat', (e) ->
    # We open the webchat, and focus on the textArea
    $('.btn-chat').hide().css("z-index","-10")
    $('#bottom_left').css("z-index","10000000").show()
    if !vars.isMobile
      $( "#duke-input" ).focus()
    # If duke-id is stored, we restore the discussion, otherwise we create a new id, store it and start a discussion
    $('.msg_container_base').children().remove()
    $('.msg_container_base').append(sessionStorage.getItem('duke-chat'))
    $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
    return

  # Hiding the chat, and removing the current discussion from it. Will be reloaded from sessionStorage if we re-open the chat
  $(document).on 'click', '.minus-link', (e) ->
    $('#bottom_left').hide().css("z-index","-10")
    $(".btn-chat").css("z-index","9999999").show()
    return

  $(document).on 'click', '.duke-default-option',  ->
    $(this).parent().toggleClass 'active'
    $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
    return

  $(document).on 'click', '.duke-select-ul li',  ->
    $(this).parents('.msg_container').remove()
    output_sent($(this).html())
    send_msg($(this).data("value"))
    return
  
  $(document).on 'click', '.control--checkbox', (evt) ->
    evt.stopPropagation();
    evt.preventDefault();
    $(this).children().last().toggleClass('duke-checked')
    $('.duke-checkbox-validation').show()
    return
  
  $(document).on 'click', '.duke-cancelation',  ->
    output_sent($(this).html())
    send_msg('*cancel*')
    return

  $(document).on 'click', '.duke-validation',  ->
    str = (($(opt).data('value') if $(opt).children().last().hasClass('duke-checked')) for opt in $('.msg_container.options.general').last().children() ).filter(Boolean).join("|||")
    output_sent($(this).html())
    send_msg(str)
    return

  # Send message & clear text area
  $(document).on 'click', '#btn-send', (e) ->
    output_sent()
    send_msg()
    if vars.stt.is_on 
      stop_stt()
    return

  # Sends message containing Option data-Value, but shows Option data-label
  $(document).on 'click', '.duke-message-option',  ->
    target = event.target || event.srcElement;
    $(this).toggleClass( "hover-fill duke-selected")
    output_sent(target.innerHTML)
    event.stopImmediatePropagation
    if event.stopPropagation then event.stopPropagation() else (event.cancelBubble = true)
    send_msg($(this).data("value"))
    return

  # Sends previous message to the functionnality the user chose when suggested
  $(document).on 'click', '.duke-suggestion',  ->
    target = event.target || event.srcElement;
    $(this).toggleClass( "hover-fill duke-selected")
    output_sent(target.innerHTML)
    if event.stopPropagation then event.stopPropagation() else (event.cancelBubble = true)
    send_msg($(this).data("value"), $(this).data("intent"))
    return


  $(document).on 'click', '#btn-mic',  ->
    console.log("vars : "+vars)
    vars.recognizer.trigger()
    return

  toEscape = 
  '&': '&amp;'
  '<': '&lt;'
  '>': '&gt;'
  '"': '&quot;'
  '\'': '&#39;'
  '/': '&#x2F;'
  '`': '&#x60;'
  '=': '&#x3D;'

  escapeHtml = (string) ->
    String(string).replace /[&<>"'`=\/]/g, (s) ->
      toEscape[s]

)(jQuery, ekylibre)
