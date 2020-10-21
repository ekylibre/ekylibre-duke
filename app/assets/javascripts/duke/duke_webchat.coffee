$.getScript 'https://js.pusher.com/7.0/pusher.min.js'
# Initialize global vars with baseUrl & regex for relocation
global_vars = {}
global_vars.base_url = window.location.protocol + '//' + location.host.split(':')[0]
global_vars.redir_regex = /<lien (.{10,}) lien>/
# Initialize webchat unless there's already a session
if !sessionStorage.getItem('duke_id')
  $.ajax '/duke_init_webchat',
    type: 'post'
    dataType: 'html'
# When Duke's data attribute is loaded, add account & pusher vals to global_vars
$(document).behave "load", "duke[data-current-account]", ->
  global_vars.account = $(this).data('current-account')
  global_vars.tenant = $(this).data('current-tenant')
  global_vars.language = $(this).data('current-language')
  global_vars.pusher_key = $(this).data('pusher-key')
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
      output_sent()
      send_msg()
      clear_textarea()
      return false
# Send msg to backends methods that communicate with IBM
send_msg = (msg = $("#duke-input").val()) ->
  $.ajax '/duke_render_msg',
    type: 'post'
    data:
      "msg": msg
      "user_id": global_vars.account
      "tenant": global_vars.tenant
      "duke_id": sessionStorage.getItem('duke_id')
    dataType: 'json'
    success: (data, status, xhr) ->
      # On message sent, open Websocket connection to listen for an answer
      pusher = new Pusher(global_vars.pusher_key, cluster: 'eu')
      channel = pusher.subscribe(sessionStorage.getItem('duke_id'))
      channel.bind 'my-event', (data) ->
        # Add received message & close websocket connection
        integrate_received(data.message)
        pusher.disconnect();
        return
      return
  return

# Create session with backend that communicates with IBM.
# Attributes a sessionID, which is stored in SessionStorage
create_session =  ->
  $.ajax '/duke_create_session',
    type: 'post'
    dataType: 'html'
    data:
      "user_id": global_vars.account
      "tenant": global_vars.tenant
    success: (data, status, xhr) ->
      sessionStorage.setItem('duke_id', data)
      send_msg("")
      return
  return

# Appends a waiting animation icon, deletes it after 0.7s
# Finds the type of the message received & outputs accordingly
# Redefines Duke-Chat sessionHistory inside SessionStorage
integrate_received = (data) ->
  # Unless it's the first message, we add the waiting animated icon
  if $('.msg_container_base').children().length > 1
    $('.msg_container_base').append('<div class="msg-list" id="waiting">
                                        <div class="responding-container">
                                          <i class="fa fa-spinner fa-spin fa-2x fa-fw"></i>
                                        </div>
                                      </div>')
    $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
  # Then 700 ms  later, we output the desired output
  setTimeout (->
    $('#waiting').remove()
    $.each data, (index, value) ->
      if value.response_type == "text"
        output_received_txt(value.text)
        if value.text.match(global_vars.redir_regex)
          location.replace global_vars.base_url + value.text.match(global_vars.redir_regex)[1]
      else if value.response_type == "option"
        output_received_txt(value.title)
        options = []
        $.each value.options, (index, value) ->
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

# If response type comports options -> Output it
output_options = (options) ->
  # We first create the container
  $('.msg_container_base').append('<div class="row msg_container options"/>')
  # Then we add every button with it's label, and it's value
  $.each options, (index, op) ->
    $('.row.msg_container.options').last().append('<button type="button" data-value= \''+op.value.input.text+'\' class="gb-bordered hover-fill option ">'+op.label+'</button>')
    return
  $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
  return

# If response type is plain text -> output it like this
output_received_txt = (msg) ->
  # We create a received container, and we append the msg to it
  $('.msg_container_base').append('<div class="msg-list">
                                    <div class="messenger-container">
                                      <p>'+msg+'</p>
                                    </div>
                                  </div>');
  $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
  return

# Disables potential buttons above & output our message in a SentMessageContainer
output_sent = (msg = $("#duke-input").val()) ->
  # Disable buttons if previous message had options selections enabled
  if $('.msg_container_base').children().last().hasClass('options')
    $.each $('.msg_container_base').children().last().children(), (index, option) ->
      $(option).prop("disabled",true);
      if !$(option).hasClass("selected")
        $(option).toggleClass( "hover-fill disabled");
      return
  # Then display the message by creating a container, and appendind msg to it
  if msg != ""
    $('.msg_container_base').append('<div class="msg-list sender">
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


# OnButtonChatClik, we show the chat window, & restore the discussion if any, or show waiting sign until ready
$(document).on 'click', '#btn_chat', (e) ->
  # We open the webchat, and focus on the textArea
  $('.btn-chat').hide()
  $('.chat-window').show()
  $( "#duke-input" ).focus()
  # If duke-id is stored, we restore the discussion, otherwise we create a new id, store it and start a discussion
  if sessionStorage.getItem('duke_id')
    $('.msg_container_base').append(sessionStorage.getItem('duke-chat'))
    $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
  else
    $('.msg_container_base').append('<i id="waiting" class="fa fa-spinner fa-spin fa-2x fa-fw"></i>')
    create_session()
  return

# Hiding the chat, and removing the current discussion from it. Will be reloaded from sessionStorage if we re-open the chat
$(document).on 'click', '.fas.fa-minus', (e) ->
  $('.chat-window').hide()
  $('.btn-chat').show()
  $('.msg_container_base').children().remove()
  return

# Send message & clear text area
$(document).on 'click', '#btn-send', (e) ->
  # Send
  output_sent()
  send_msg()
  clear_textarea()
  return

# Sends message containing Option data-Value, but shows Option data-label
$(document).on 'click', '.option',  ->
  target = event.target || event.srcElement;
  $(this).toggleClass( "hover-fill selected")
  output_sent(target.innerHTML)
  if event.stopPropagation then event.stopPropagation() else (event.cancelBubble = true)
  send_msg($(this).data("value"))
  return

# STT integration
recognition = new webkitSpeechRecognition
recognition.continuous = true
recognition.interimResults = true
recognition.lang = 'fr-FR'

recognition.onresult = (event) ->
  interim_transcript = ''
  final_transcript = ''
  i = event.resultIndex
  while i < event.results.length
    # Verify if the recognized text is the last with the isFinal property
    if event.results[i].isFinal
      final_transcript += event.results[i][0].transcript
    else
      interim_transcript += event.results[i][0].transcript
    ++i
  # If message is over ie last transcript was null -> We send the output & clear textarea & buttonMic
  if interim_transcript == ""
    $("#duke-input").val(final_transcript)
    output_sent()
    send_msg()
    clear_textarea()
    $("#btn-mic").toggleClass("send-enabled", false)
    $("#btn-mic").toggleClass("disabled-send",false)
    recognition.stop()
  # Or we add interim transcription to Duke's textarea
  else
    $( "#duke-input" ).val(interim_transcript)
  return

recognition.onerror = (event) ->
  recognition.stop()
  return

# On end, Mic button is clickable and back base style
recognition.onend = ->
  clear_textarea()
  $("#btn-mic").toggleClass("send-enabled", false)
  $("#btn-mic").toggleClass("disabled-send",false)
  console.log 'Speech recognition service disconnected'
  return

# On mic click, btn is disabled & new style
$(document).on 'click', '#btn-mic', (e) ->
  $("#btn-mic").toggleClass("send-enabled",true)
  $("#btn-mic").toggleClass("disabled-send",true)
  recognition.start()
  return
