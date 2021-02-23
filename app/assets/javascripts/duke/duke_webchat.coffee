(($, E) ->
  base_url = window.location.protocol + '//' + location.host.split(':')[0]
  redirectionReg = /redirect(keep)?=(.{10,})/
  cancelationReg = new RegExp('annul', 'i')

  class DukeWebchat
    constructor = (@account, @tenant, @pusher_key) ->
      @pusher_cluster = "eu"
      @empty_history = false;
      @isMobile = /(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|ipad|iris|kindle|Android|Silk|lge |maemo|midp|mmp|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows (ce|phone)|xda|xiino/i.test(navigator.userAgent) or /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(navigator.userAgent.substr(0, 4))

    init = ->
      if sessionStorage.getItem('duke-chat')
        vars.pusher_channel.unbind 'duke'
        vars.pusher.disconnect()
        if (sessionStorage.duke_visible)
          instanciate_pusher(persist_duke())
          sessionStorage.removeItem('duke_visible')
        else
          instanciate_pusher($('.btn-chat').show())
      else 
        create_session()
      return 

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
          instanciate_pusher(msg_callback())
          return
      return

    instanciate_pusher = (callback) -> 
      if typeof Pusher != 'undefined'
        pusher = new Pusher(@pusher_key, cluster: @pusher_cluster)
        pusher_channel = vars.pusher.subscribe(sessionStorage.getItem('duke_id'))
        pusher_channel.bind 'duke', (data) ->
          this.integrate_received(data.message)
          $(".btn-chat").css("z-index","9999999").show()
          return
        pusher.connection.bind('pusher_internal:subscription_succeeded', callback)
      else 
        setTimeout instanciate_pusher, 200
      return 

    msg_callback = -> 
      setTimeout (->
        send_msg("")
        return
      ), 1000
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

    # Disables potential buttons above & output our message in a SentMessageContainer
    output_sent = (msg = $("#duke-input").val().replace(/\n/g, "")) ->
      disable_buttons() 
      if msg # Then display the message by creating a container, and appendind msg to it
        $('.msg_container_base').append('<div class="msg-list sender msg-sdd"><div class="messenger-container"><p>'+msg+'</p></div></div>');
        $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
      return

    disable_buttons = -> 
      $(".duke-select-wrap").last().parent().remove()
      $(".duke-centered").last().remove()
      if $('.msg_container_base').children().last().hasClass('options') 
        $.each $('.msg_container_base').children().last().children(), (index, option) ->
          $(option).prop("disabled",true);
          if !$(option).hasClass("duke-selected")
            $(option).toggleClass( "hover-fill duke-disabled");
      return

    # Finds the type of the message received & outputs accordingly
    integrate_received = (data) ->
      $.each data, (index, value) ->
        text = `value.response_type == "text" ? value.text : value.title`
        options = `value.response_type == "option" ? (val for val in value.options) : (val for val in value.suggestions)`
        new DukeMessage(value.response_type, text, options).display()
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


  class Message
    multChoicesReg = /=multiple_choices/
    constructor = (@type, @text, @options)-> 

    display = -> 
      loading_message()
      setTimeout (-> 
        $('#waiting').remove()
        this.redirect() 
        this.output_received_text(@text)
        this.output_received_options(@options)
      ), 700
      return

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

    output_options = () ->
      if @options.length > 0 
        $('.msg_container_base').append('<div class="msg_container options general"></div>')
        # Then we add every button with it's label, and it's value, and the potential intent to redirect the user
        if multChoicesReg.test(@text) 
          this.multiple_options()
        else  
          if options.length > 7
            dropdown_options()
          else 
            single_options()
        $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
      return

    multiple_options = -> 
      $.each @options, (index, op) -> 
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
      return

    single_options = -> 
      $.each options, (index, op) ->
        if op.hasOwnProperty('source_dialog_node')
          intent = op.value.input.intents.length == 0 ? "none_of_the_above" : op.value.input.intents[0].intent
          $('.msg_container.options').last().append('<button type="button" data-value= \''+escapeHtml(op.value.input.text)+'\'data-intent= \''+escapeHtml(intent)+'\' class="gb-bordered hover-fill duke-option duke-suggestion ">'+escapeHtml(op.label)+'</button>')
        else 
          $('.msg_container.options').last().append('<button type="button" data-value= \''+escapeHtml(op.value.input.text)+'\' class="gb-bordered hover-fill duke-option duke-message-option">'+escapeHtml(op.label)+'</button>')
      return

    dropdown_options = -> 
      $('.msg_container.options').last().append('<div class="duke-select-wrap"><ul class="duke-default-option"><li><div class="option">
                                                        <p>Choisissez une option</p></div></li></ul><ul class="duke-select-ul"></ul>
                                                    </div>')
      $.each @options, (index, op) -> 
        $('.duke-select-ul').last().append('<li data-value= \''+escapeHtml(op.value.input.text)+'\'><div class="option">
                                              <p>'+escapeHtml(op.label)+'</p></div>
                                            </li>')
      return

    redirect = -> 
      if redirection = @text.match(redirectionReg)
        location.replace vars.base_url + redirection[2] 
        duke_chat = redirection[1] ? "<div class='messenger-container duke-received'><p>Bienvenue, je vous écoute</p></div>" : (msg.outerHTML for msg in $('.msg_container_base').children()).join("")
        if redirection[1] 
          sessionStorage.setItem('duke_visible', true)
        sessionStorage.setItem('duke-chat', duke_chat)
      if @text.indexOf('#base-url') >= 0
        @text = @text.replace('#base-url', vars.base_url)
      return 

    loading_message = -> 
      $('.msg_container_base').append('<div class="msg-list msg-rcvd" id="waiting"><div class="messenger-container">
                                          <svg width="38" height="38" viewBox="0 0 38 38" xmlns="http://www.w3.org/2000/svg"><defs><linearGradient x1="8.042%" y1="0%" x2="65.682%" y2="23.865%" id="a"><stop stop-color="black" stop-opacity="0" offset="0%"/><stop stop-color="black" stop-opacity=".631" offset="63.146%"/><stop stop-color="black" offset="100%"/></linearGradient></defs>
                                            <g fill="none" fill-rule="evenodd"><g transform="translate(1 1)"><path d="M36 18c0-9.94-8.06-18-18-18" id="Oval-2" stroke="url(#a)" stroke-width="2"><animateTransform attributeName="transform"type="rotate"from="0 18 18"to="360 18 18"dur="0.5s"repeatCount="indefinite" /></path><circle fill="black" cx="36" cy="18" r="1"><animateTransform attributeName="transform"type="rotate"from="0 18 18"to="360 18 18"dur="0.5s"repeatCount="indefinite" /></circle></g></g></svg></div></div>')
      $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
      return
)(jQuery, ekylibre)