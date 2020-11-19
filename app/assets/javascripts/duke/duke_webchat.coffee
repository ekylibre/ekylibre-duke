$.getScript 'https://js.pusher.com/7.0/pusher.min.js'
# When Duke's data attribute is loaded, add account & pusher vals to global_vars
# Initialize global vars with baseUrl & regex for relocation
global_vars = {}
if /(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|ipad|iris|kindle|Android|Silk|lge |maemo|midp|mmp|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows (ce|phone)|xda|xiino/i.test(navigator.userAgent) or /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(navigator.userAgent.substr(0, 4))
  global_vars.isMobile = true
else 
  global_vars.isMobile = false
global_vars.base_url = window.location.protocol + '//' + location.host.split(':')[0]
# TODO : Replace old regex with second one, more efficient with our own webchat
global_vars.redir_regex = /<lien (.{10,}) lien>/
global_vars.redir_sec_regex = /_____(.{10,})/
global_vars.stt = {}
$(document).behave "load", "duke[data-current-account]", ->
  global_vars.account = $(this).data('current-account')
  global_vars.tenant = $(this).data('current-tenant')
  global_vars.language = $(this).data('current-language')
  global_vars.pusher_key = $(this).data('pusher-key')
  global_vars.azure_key = $(this).data('azure-key')
  global_vars.azure_region = $(this).data('azure-region')
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
      $('#btn-send').toggleClass("disabled-send", true)
      $("#btn-send").toggleClass("send-enabled",false)
    else
      $('#btn-send').toggleClass("disabled-send", false)
      $("#btn-send").toggleClass("send-enabled",true)
    return
  # Before sending keyValue to Duke's Textarea -> If PressedKey is enter -> Send Message
  $('#duke-input').keydown (e) ->
    code = if e.keyCode then e.keyCode else e.which
    if code == 13
      if $("#duke-input").val() != ""
        output_sent()
        send_msg()
      return false
      
  create_session =  ->
    $.ajax '/duke_create_session',
      type: 'post'
      dataType: 'json'
      data:
        "user_id": global_vars.account
        "tenant": global_vars.tenant
      success: (data, status, xhr) ->
        sessionStorage.setItem('duke_id', data.session_id)
        sessionStorage.setItem('assistant_id', data.assistant_id)
        global_vars.pusher = new Pusher(global_vars.pusher_key, cluster: 'eu')
        channel = global_vars.pusher.subscribe(sessionStorage.getItem('duke_id'))
        channel.bind 'my-event', (data) ->
          # Add received message
          integrate_received(data.message)
          return
        send_msg("")
        return
    return

  waitforDukeMsg = ->
    if sessionStorage.getItem('duke-chat')
      # Adding the chat btn 
      $(document.body).append('<submit class="btn-chat">
                                <svg version="1.1" class="icon-chat" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px"
                                  viewBox="0 0 200 200" style="enable-background:new 0 0 200 200;" xml:space="preserve">
                                  <g>
                                  <g>
                                    <path class="st0" d="M111.2,182.6l-11.1-6.4l25.4-44.5h38.1c7,0,12.7-5.7,12.7-12.7V42.8c0-7-5.7-12.7-12.7-12.7H36.5
                                      c-7,0-12.7,5.7-12.7,12.7v76.3c0,7,5.7,12.7,12.7,12.7h57.2v12.7H36.5c-14,0-25.4-11.4-25.4-25.4V42.8c0-14,11.4-25.4,25.4-25.4
                                      h127.1c14,0,25.4,11.4,25.4,25.4v76.3c0,14-11.4,25.4-25.4,25.4h-30.8L111.2,182.6z"/>
                                    <path class="st0" d="M49.2,55.5h101.7v12.7H49.2V55.5z M49.2,93.6h63.6v12.7H49.2V93.6z"/>
                                  </g>
                                </g>
                                </svg>
                              </submit>');
    else
      setTimeout waitforDukeMsg, 1000
    return

  # Send msg to backends methods that communicate with IBM
  send_msg = (msg = $("#duke-input").val().replace(/\n/g, ""), user_intent=undefined) ->
    reset_textarea() 
    clear_textarea()
    if !global_vars.pusher
      global_vars.pusher = new Pusher(global_vars.pusher_key, cluster: 'eu')
      channel = global_vars.pusher.subscribe(sessionStorage.getItem('duke_id'))
      channel.bind 'my-event', (data) ->
        # Add received message
        integrate_received(data.message)
        return
    # On message sent, open Websocket connection to listen for an answer
    $.ajax '/duke_send_msg',
      type: 'post'
      data:
        "msg": msg
        "user_intent": user_intent
        "user_id": global_vars.account
        "tenant": global_vars.tenant
        "duke_id": sessionStorage.getItem('duke_id')
        "assistant_id": sessionStorage.getItem('assistant_id')
      dataType: 'json'
    return
  if !sessionStorage.getItem('duke_id')
    create_session()
    waitforDukeMsg()
  else 
    $(document.body).append('<submit class="btn-chat">
                              <svg version="1.1" class="icon-chat" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px"
                                viewBox="0 0 200 200" style="enable-background:new 0 0 200 200;" xml:space="preserve">
                                <g>
                                <g>
                                  <path class="st0" d="M111.2,182.6l-11.1-6.4l25.4-44.5h38.1c7,0,12.7-5.7,12.7-12.7V42.8c0-7-5.7-12.7-12.7-12.7H36.5
                                    c-7,0-12.7,5.7-12.7,12.7v76.3c0,7,5.7,12.7,12.7,12.7h57.2v12.7H36.5c-14,0-25.4-11.4-25.4-25.4V42.8c0-14,11.4-25.4,25.4-25.4
                                    h127.1c14,0,25.4,11.4,25.4,25.4v76.3c0,14-11.4,25.4-25.4,25.4h-30.8L111.2,182.6z"/>
                                  <path class="st0" d="M49.2,55.5h101.7v12.7H49.2V55.5z M49.2,93.6h63.6v12.7H49.2V93.6z"/>
                                </g>
                              </g>
                              </svg>
                            </submit>');

  # Appends a waiting animation icon, deletes it after 0.7s
  # Finds the type of the message received & outputs accordingly
  # Redefines Duke-Chat sessionHistory inside SessionStorage
  integrate_received = (data) ->
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
    $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
    # Then 700 ms  later, we output the desired output
    setTimeout (->
      $('#waiting').remove()
      $.each data, (index, value) ->
        if value.response_type == "text"
          if value.text.match(global_vars.redir_sec_regex)
            location.replace global_vars.base_url + ":3000" + value.text.match(global_vars.redir_sec_regex)[1]
            value.text = value.text.replace(value.text.match(global_vars.redir_sec_regex)[0], "")
          if value.text.match(global_vars.redir_regex)
            location.replace global_vars.base_url + ":3000" + value.text.match(global_vars.redir_regex)[1]
          if value.text.indexOf('#base-url') >= 0
            value.text = value.text.replace('#base-url', global_vars.base_url +":3000")
          output_received_txt(value.text)
        else if value.response_type == "option"
          output_received_txt(value.title)
          options = []
          $.each value.options, (index, value) ->
            options.push(value)
            return
          output_options(options)
        else if value.response_type == "suggestion"
          output_received_txt(value.title)
          options = []
          $.each value.suggestions, (index, value) ->
            options.push(value)
            return
          output_options(options)
        return
      # And we add all the discussion history to sessionStorage
      html = ''
      $.each $('.msg_container_base').children(), (index, msg) ->
          html += this.outerHTML;
          return
      sessionStorage.setItem('duke-chat', html)
      return
    ), 700
    return

  # If response type comports options, or suggestion -> Output it as clickable buttons
  output_options = (options, type="options") ->
    # We first create the container
    $('.msg_container_base').append('<div class="row msg_container options"/>')
    # Then we add every button with it's label, and it's value, and the potential intent to redirect the user
    $.each options, (index, op) ->
      if op.hasOwnProperty('source_dialog_node')
        if op.value.input.intents.length == 0
          intent = "anything_else"
        else 
          intent = op.value.input.intents[0].intent
        $('.row.msg_container.options').last().append('<button type="button" data-value= \''+op.value.input.text+'\'data-intent= \''+intent+'\' class="gb-bordered hover-fill duke-option duke-suggestion ">'+op.label+'</button>')
      else 
        $('.row.msg_container.options').last().append('<button type="button" data-value= \''+op.value.input.text+'\' class="gb-bordered hover-fill duke-option duke-message-option">'+op.label+'</button>')
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
    if $('.msg_container_base').children().last().hasClass('options')
      $.each $('.msg_container_base').children().last().children(), (index, option) ->
        $(option).prop("disabled",true);
        if !$(option).hasClass("selected")
          $(option).toggleClass( "hover-fill disabled");
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

  # TextArea is reset, Send button is disabled
  clear_textarea = ->
    # TextArea gets cleared, and send-btn gets disabled
    $('#btn-send').toggleClass("disabled-send", true)
    $("#btn-send").toggleClass("send-enabled",false)
    $("#duke-input").val("")
    return
  
  reset_textarea = -> 
    $('#duke-input').css('height', '60px')
    $('.msg_container_base').css('height', $('#bottom_left').height() - 105)
    return

  $(window).resize ->
    $('.msg_container_base').css('height', $('#bottom_left').height() - 105)
    return



  # OnButtonChatClik, we show the chat window, & restore the discussion if any, or show waiting sign until ready
  $(document).on 'click', '.btn-chat', (e) ->
    # We open the webchat, and focus on the textArea
    $('.btn-chat').hide()
    $(".btn-chat").css("z-index","-10");
    $('#bottom_left').css("z-index","100000");
    $('#bottom_left').show()
    if !global_vars.isMobile
      $( "#duke-input" ).focus()
    # If duke-id is stored, we restore the discussion, otherwise we create a new id, store it and start a discussion
    $('.msg_container_base').children().remove()
    $('.msg_container_base').append(sessionStorage.getItem('duke-chat'))
    $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
    return

  # Hiding the chat, and removing the current discussion from it. Will be reloaded from sessionStorage if we re-open the chat
  $(document).on 'click', '.minus-link', (e) ->
    $('#bottom_left').hide()
    $('#bottom_left').css("z-index","-10");
    $(".btn-chat").css("z-index","100000");
    $('.btn-chat').show()
    return

  # Send message & clear text area
  $(document).on 'click', '#btn-send', (e) ->
    # Send
    output_sent()
    send_msg()
    if global_vars.stt.is_on 
      stop_stt()
    return

  # Sends message containing Option data-Value, but shows Option data-label
  $(document).on 'click', '.duke-message-option',  ->
    target = event.target || event.srcElement;
    $(this).toggleClass( "hover-fill selected")
    output_sent(target.innerHTML)
    if event.stopPropagation then event.stopPropagation() else (event.cancelBubble = true)
    send_msg($(this).data("value"))
    return

  # Sends previous message to the functionnality the user chose when suggested
  $(document).on 'click', '.duke-suggestion',  ->
    target = event.target || event.srcElement;
    $(this).toggleClass( "hover-fill selected")
    output_sent(target.innerHTML)
    if event.stopPropagation then event.stopPropagation() else (event.cancelBubble = true)
    send_msg($(this).data("value"), $(this).data("intent"))
    return

  $('#duke-input').focusin ->
    base_color = $('#top_bar').css('background-color')
    $('#btn-mic').css('border-color', base_color)
    return

  $('#duke-input').focusout ->
    $('#btn-mic').css('border-color', 'lightgray')
    return

  # STT integration
  global_vars.stt.stt_on = false
  $(document).on 'click', '#btn-mic', (e) ->
    transcript = ""
    # If stt is on, we stop the recognizer and send the message
    if global_vars.stt.is_on 
      stop_stt()
      if $("#duke-input").val() != ""
        output_sent()
        send_msg()
    else 
      # If stt is off, we start recording and printing transcription to textarea
      global_vars.stt.is_on = true
      # Limiting speech recognition to 20 seconds
      $(this).delay(20000).queue ->
        if global_vars.stt.is_on 
          stop_stt()
          return
      # Creating STT config if non existent
      if !("speechConfig" in global_vars.stt)
        global_vars.stt.speechConfig = SpeechSDK.SpeechConfig.fromSubscription(global_vars.azure_key, global_vars.azure_region);
        global_vars.stt.speechConfig.speechRecognitionLanguage = "fr-FR";
        global_vars.stt.audioConfig  = SpeechSDK.AudioConfig.fromDefaultMicrophoneInput();
      # Launching recognition
      global_vars.stt.recognizer = new (SpeechSDK.SpeechRecognizer)(global_vars.stt.speechConfig, global_vars.stt.audioConfig);
      $("#btn-mic").toggleClass("send-enabled",true)
      global_vars.stt.recognizer.startContinuousRecognitionAsync()
      # On intermediate responses
      global_vars.stt.recognizer.recognizing = (s, e) ->
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
      global_vars.stt.recognizer.recognized = (s, e) ->
        transcript += e.result.text.replace(/.$/," ")
        return

  # Function used to stop STT, and remove recognizer Element
  stop_stt = ->
      $("#btn-mic").toggleClass("send-enabled",false)
      global_vars.stt.recognizer.stopContinuousRecognitionAsync ->
      global_vars.stt.recognizer.close()
      global_vars.stt.recognizer = undefined
      global_vars.stt.is_on = false
    return