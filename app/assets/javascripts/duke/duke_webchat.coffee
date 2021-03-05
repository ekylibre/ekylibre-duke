#= require action_cable
(($, E) ->
  # Initializing duke vars with empty hash
  vars = {}
  vars.base_url = window.location.protocol + '//' + location.host.split(':')[0]
  vars.redirection = /redirect(keep)?=(.{10,})/
  vars.cancelation = new RegExp('annul', 'i')
  vars.stt = {}
  vars.empty_history = false
  if /(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|ipad|iris|kindle|Android|Silk|lge |maemo|midp|mmp|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows (ce|phone)|xda|xiino/i.test(navigator.userAgent) or /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(navigator.userAgent.substr(0, 4))
    vars.isMobile = true
  else 
    vars.isMobile = false
  # When duke data attribute gets loaded, set values & instanciate acionCable to show chat-btn
  $(document).behave "load", "duke[data-current-account]", ->
    # Setting user attributes inside vars
    vars.account = $(this).data('current-account')
    vars.tenant = $(this).data('current-tenant')
    vars.language = $(this).data('current-language')
    vars.cable_url = $(this).data('cable-url')
    vars.azure_key = $(this).data('azure-key')
    vars.azure_region = $(this).data('azure-region')
    # Create Session is session is empty , or we show btn-chat when cable is subscribed to DukeChannel
    if sessionStorage.getItem('duke-chat')
      # If channels are still defined, unbind duke subscription (we recreate it right after) to avoid duplicates
      if !vars.duke_subscription
        cable_subscribe()
      else 
        $('.btn-chat').show()
    else 
      create_session()
    # Allowing TextArea autosize
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
      
  # Creatig Duke session via Method in DukeWebchatController, storing assistant_id and session_id in sessionStorage and subscribe to cable to display chat-btn
  create_session =  ->
    $.ajax '/duke_create_session',
      type: 'post'
      dataType: 'json'
      data:
        "user_id": vars.account
        "tenant": vars.tenant
      success: (data, status, xhr) ->
        sessionStorage.setItem('duke_id', data.session_id)
        sessionStorage.setItem('assistant_id', data.assistant_id)
        cable_subscribe()
        return
    return

  cable_subscribe = -> 
    vars.cable = ActionCable.createConsumer(vars.base_url.replace("http","ws")+vars.cable_url)
    vars.duke_subscription = vars.cable.subscriptions.create(channel: 'DukeChannel', roomId: sessionStorage.getItem('duke_id'),
      received: (data) ->
        integrate_received(data.message)
        $('.btn-chat').show()
      connected: -> 
        if !sessionStorage.getItem('duke-chat')
          send_msg("")
        else 
          $('.btn-chat').show()
    )
    return

  # Send msg to backends methods that communicate with IBM, if intent is specified, msg goes straight to this functionnality (intent disambiguation)
  send_msg = (msg = $("#duke-input").val().replace(/\n/g, ""), user_intent=undefined) ->
    if msg.toString().match(vars.cancelation)
      user_intent = "quick_exit"
    reset_textarea() 
    clear_textarea()

    $.ajax '/duke_send_msg',
      type: 'post'
      data:
        "msg": msg
        "user_intent": user_intent
        "user_id": vars.account
        "tenant": vars.tenant
        "duke_id": sessionStorage.getItem('duke_id')
        "assistant_id": sessionStorage.getItem('assistant_id')
      dataType: 'json'
    return

  # Finds the type of the message received & outputs accordingly
  integrate_received = (data) ->
    # Appends a waiting animation icon, deletes it after 0.7s
    add_loading_icon()
    $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
    # Then 700 ms  later, we output the desired output
    setTimeout (->
      $('#waiting').remove()
      $.each data, (index, value) ->
        if value.response_type == "text"
          current_redir = value.text.match(vars.redirection)
          if current_redir
            location.replace vars.base_url + current_redir[2]
            value.text = value.text.replace(current_redir[0], "")
            if current_redir[1]
              sessionStorage.setItem('duke_visible', true)
            else
              vars.empty_history = true
          if value.text.indexOf('#base-url') >= 0
            value.text = value.text.replace('#base-url', vars.base_url)
          output_received_txt(value.text)
        else if value.response_type == "option"
          output_received_txt(value.title.replace(/=multiple_choices/, ""))
          options = (val for val in value.options)
          output_options(options, multiple=/=multiple_choices/.test(value.title))
        else if value.response_type == "suggestion"
          output_received_txt(value.title)
          options = (val for val in value.suggestions)
          output_options(options)
        return
      # And we add all the discussion history to sessionStorage
      if vars.empty_history
        sessionStorage.setItem('duke-chat', "<div class='messenger-container duke-received'><p>Bienvenue, je vous écoute</p></div>")
      else 
        sessionStorage.setItem('duke-chat', (msg.outerHTML for msg in $('.msg_container_base').children()).join(""))
    ), 700
    return

  # If response type comports options, or suggestion -> Output it as clickable buttons
  output_options = (options, multiple=false) ->
    # We first create the container
    $('.msg_container_base').append('<div class="msg_container options general"></div>')
    # Then we add every button with it's label, and it's value, and the potential intent to redirect the user
    if multiple 
      $.each options, (index, op) -> 
          if op.hasOwnProperty('global_label')
             $('.msg_container.options').last().append('<p class = "duke-multi-label">'+op.global_label+'</p>')
 
          else
            $('.msg_container.options').last().append('<label data-value= \''+escapeHtml(op.value.input.text)+'\'class="control control--checkbox">'+escapeHtml(op.label)+'
                                                        <input type="checkbox"/>
                                                        <div class="control__indicator"></div>
                                                      </label>')
        $('.msg_container.options').last().append('<div class="msg_container options duke-centered">
                                                      <button type="button" class="gb-bordered hover-fill duke-option duke-checkbox-validation duke-validation ">Valider</button>
                                                      <button type="button" class="gb-bordered hover-fill duke-option duke-cancelation ">Retour</button>
                                                    </div>')
    else  
      count = ((opt if opt.hasOwnProperty('global_label')) for opt in options).filter(Boolean).length
      if options.length - count > 7
        $('.msg_container.options').last().append('<div class="duke-select-wrap"><ul class="duke-default-option"><li><div class="option">
                                                      <p>Choisissez une option</p></div></li></ul><ul class="duke-select-ul"></ul>
                                                  </div>')
        $.each options, (index, op) -> 
          if op.hasOwnProperty('global_label')
            $('.duke-select-ul').last().append('<p class="duke-dropdown-label">'+escapeHtml(op.global_label)+'</p>')
          else 
            $('.duke-select-ul').last().append('<li data-value= \''+escapeHtml(op.value.input.text)+'\'><div class="option">
                                                  <p>'+escapeHtml(op.label)+'</p></div>
                                                </li>')
      else 
        $.each options, (index, op) ->
          if op.hasOwnProperty('source_dialog_node')
            if op.value.input.intents.length == 0
              intent = "none_of_the_above"
            else 
              intent = op.value.input.intents[0].intent
            $('.msg_container.options').last().append('<button type="button" data-value= \''+escapeHtml(op.value.input.text)+'\'data-intent= \''+escapeHtml(intent)+'\' class="gb-bordered hover-fill duke-option duke-suggestion ">'+escapeHtml(op.label)+'</button>')
          else 
            $('.msg_container.options').last().append('<button type="button" data-value= \''+escapeHtml(op.value.input.text)+'\' class="gb-bordered hover-fill duke-option duke-message-option">'+escapeHtml(op.label)+'</button>')
          return
    $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
    return

  # If response type is plain text -> output it like this
  output_received_txt = (msg) ->
    # We create a received container, and we append the msg to it
    $('.duke-received:last p:first').css("border-style", "unset");
    $('.msg_container_base').append('<div class="msg-list msg-rcvd">
                                      <div class="messenger-container duke-received">
                                        <p>'+msg+'</p>
                                      </div>
                                    </div>');
    $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
    return

  # Disables potential buttons above & output our message in a SentMessageContainer
  output_sent = (msg = $("#duke-input").val().replace(/\n/g, "")) ->
    # Disable buttons if previous message had options selections enabled
    $(".duke-select-wrap").last().parent().remove()
    $(".duke-centered").last().remove()
    if $('.msg_container_base').children().last().hasClass('options') 
      $.each $('.msg_container_base').children().last().children(), (index, option) ->
        $(option).prop("disabled",true);
        if !$(option).hasClass("duke-selected")
          $(option).toggleClass( "hover-fill duke-disabled");
        return
    # Then display the message by creating a container, and appendind msg to it
    if msg != ""
      $('.msg_container_base').append('<div class="msg-list sender msg-sdd">
                                        <div class="messenger-container">
                                          <p>'+msg+'</p>
                                        </div>
                                      </div>');
      $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
    return

  persist_duke = -> 
    $('.msg_container_base').append(sessionStorage.getItem('duke-chat'))
    $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
    $('#bottom_left').css("z-index","10000000").show()
    return

  clear_textarea = ->
    # TextArea gets cleared, and send-btn gets disabled
    $('#btn-send').toggleClass("disabled-send", true).toggleClass("send-enabled",false)
    $("#duke-input").val("")
    return

  reset_textarea = -> 
    $('#duke-input').css('height', '60px')
    $('.msg_container_base').css('height', $('#bottom_left').height() - $('.input-flex').height() - 45)
    return

  $(window).resize ->
    $('.msg_container_base').css('height', $('#bottom_left').height() - $('.input-flex').height() - 45)
    return

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

  # STT integration
  vars.stt.stt_on = false
  $(document).on 'click', '#btn-mic', (e) ->
    transcript = ""
    # If stt is on, we stop the recognizer and send the message
    if vars.stt.is_on
      stop_stt()
      if $("#duke-input").val() != ""
        output_sent()
        send_msg()
    else 
      # If stt is off, we start recording and printing transcription to textarea
      vars.stt.is_on = true
      # Limiting speech recognition to 20 seconds
      vars.stt_timeout = setTimeout((->
        if vars.stt.is_on 
          stop_stt()
          return
      ), 20000)
      # Creating STT config if non existent
      if !("speechConfig" in vars.stt)
        vars.stt.speechConfig = SpeechSDK.SpeechConfig.fromSubscription(vars.azure_key, vars.azure_region);
        vars.stt.speechConfig.speechRecognitionLanguage = "fr-FR";
        vars.stt.audioConfig  = SpeechSDK.AudioConfig.fromDefaultMicrophoneInput();
      # Launching recognition
      vars.stt.recognizer = new (SpeechSDK.SpeechRecognizer)(vars.stt.speechConfig, vars.stt.audioConfig);
      $("#btn-mic").toggleClass("send-enabled",true)
      vars.stt.recognizer.startContinuousRecognitionAsync()
      # On intermediate responses
      vars.stt.recognizer.recognizing = (s, e) ->
        if vars.stt.is_on
          $("#duke-input").val(transcript+" "+e.result.text)
          $('#duke-input').css('height', 'auto')
          height = $("#duke-input").prop('scrollHeight')
          $('.msg_container_base').css('height', $('#bottom_left').height() - height - 45)
          $('#duke-input').css('height', height + 'px')
          $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight)
          if !($( "#duke-input" ).hasClass( "send-enabled"))
            $('#btn-send').toggleClass("disabled-send", false)
            $("#btn-send").toggleClass("send-enabled",true)
          return
      # On final sentence recognition
      vars.stt.recognizer.recognized = (s, e) ->
        transcript += e.result.text.replace(/.$/," ")
        return

  # Function used to stop STT, and remove recognizer Element
  stop_stt = ->
    clearTimeout(vars.stt_timeout)
    $("#btn-mic").toggleClass("send-enabled",false)
    vars.stt.recognizer.stopContinuousRecognitionAsync ->
    vars.stt.recognizer.close()
    vars.stt.recognizer = undefined
    vars.stt.is_on = false
    return
  add_loading_icon = ->
    $('.msg_container_base').append('<div class="msg-list msg-rcvd" id="waiting">
                                      <div class="messenger-container">
                                        <svg width="38" height="38" viewBox="0 0 38 38" xmlns="http://www.w3.org/2000/svg">
                                          <defs>
                                              <linearGradient x1="8.042%" y1="0%" x2="65.682%" y2="23.865%" id="a">
                                                  <stop stop-color="black" stop-opacity="0" offset="0%"/>
                                                  <stop stop-color="black" stop-opacity=".631" offset="63.146%"/>
                                                  <stop stop-color="black" offset="100%"/>
                                              </linearGradient>
                                          </defs>
                                          <g fill="none" fill-rule="evenodd">
                                              <g transform="translate(1 1)">
                                                  <path d="M36 18c0-9.94-8.06-18-18-18" id="Oval-2" stroke="url(#a)" stroke-width="2">
                                                      <animateTransform
                                                          attributeName="transform"
                                                          type="rotate"
                                                          from="0 18 18"
                                                          to="360 18 18"
                                                          dur="0.5s"
                                                          repeatCount="indefinite" />
                                                  </path>
                                                  <circle fill="black" cx="36" cy="18" r="1">
                                                      <animateTransform
                                                          attributeName="transform"
                                                          type="rotate"
                                                          from="0 18 18"
                                                          to="360 18 18"
                                                          dur="0.5s"
                                                          repeatCount="indefinite" />
                                                  </circle>
                                              </g>
                                          </g>
                                        </svg>
                                      </div>
                                    </div>')
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
