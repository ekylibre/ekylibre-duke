(function (E, $) {
  const multChoicesReg = /=multiple_choices/;
  const base_url = window.location.protocol + '//' + location.host.split(':')[0];
  const base_urlReg = /#base-url/;
  const redirectionReg = /redirect(keep)?=(.{10,})/;
  const cancelationReg = new RegExp('annul', 'i');
  var duke = {}

  escapeHtml = function(string) {
    const toEscape = {'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', '\'': '&#39;', '/': '&#x2F;', '`': '&#x60;','=': '&#x3D;'};
    return String(string).replace(/[&<>"'`=\/]/g, function(s) {
      return toEscape[s];
    });
  };

  E.onDomReady(function () {
    duke.webchat = duke.webchat ? duke.webchat : new DukeWebchat($("duke").data('current-account'), $("duke").data('current-tenant'), $("duke").data('pusher-key'), $("duke").data('azure-key'), $("duke").data('azure-region'))
    duke.webchat.init()

    $('#duke-input').keydown(function(e) {
      var code = e.keyCode ? e.keyCode : e.which;
      if (code === 13) {
        if ($("#duke-input").val()) {
          duke.webchat.output_sent();
          duke.webchat.send_msg();
        }
        return false;
      }
    });

    $('#duke-input').focusin(function() {
      $('#btn-mic').css('border-color', $('#top_bar').css('background-color'));
    });

    $('#duke-input').focusout(function() {
      $('#btn-mic').css('border-color', 'lightgray');
    });

    $('#duke-input').keyup(function(e) {
      if ($("#duke-input").val() === "") {
        $('#btn-send').toggleClass("disabled-send", true).toggleClass("send-enabled", false);
      } else {
        $('#btn-send').toggleClass("disabled-send", false).toggleClass("send-enabled", true);
      }
    });

    $('#duke-input').each(function() {
      this.setAttribute('style', 'height:' + this.scrollHeight + 'px;overflow-y:hidden;');
    }).on('input', function() {
      this.style.height = 'auto';
      $('.msg_container_base').css('height', $('#bottom_left').height() - this.scrollHeight - 45);
      this.style.height = this.scrollHeight + 'px';
      $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
    });

    $(document).on('click', '.btn-chat', function(e) {
      $('.btn-chat').hide().css("z-index", "-10");
      $('#bottom_left').css("z-index", "10000000").show();
      if (duke.webchat.isMobile) {
        $("#duke-input").focus();
      }
      $('.msg_container_base').children().remove();
      $('.msg_container_base').append(sessionStorage.getItem('duke-chat'));
      $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
    });

    $(document).on('click', '.minus-link', function() {
      $('#bottom_left').hide().css("z-index", "-10");
      $(".btn-chat").css("z-index", "9999999").show();
    });

    $(document).on('click', '.duke-default-option', function() {
      $(this).parent().toggleClass('active');
      $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
    });

    $(document).on('click', '.duke-select-ul li', function() {
      $(this).parents('.msg_container').remove();
      duke.webchat.output_sent($(this).html());
      duke.webchat.send_msg($(this).data("value"));
    });

    $(document).on('click', '.control--checkbox', function(evt) {
      evt.stopPropagation();
      evt.preventDefault();
      $(this).children().last().toggleClass('duke-checked');
      $('.duke-checkbox-validation').show();
    });

    $(document).on('click', '.duke-cancelation', function() {
      duke.webchat.output_sent($(this).html());
      duke.webchat.send_msg('*cancel*');
    });

    $(document).on('click', '.duke-validation', function() {
      var opt, str;
      str = ((function() {
        var _i, _len, _ref, _results;
        _ref = $('.msg_container.options.general').last().children();
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          opt = _ref[_i];
          _results.push($(opt).children().last().hasClass('duke-checked') ? $(opt).data('value') : void 0);
        }
        return _results;
      })()).filter(Boolean).join("|||");
      duke.webchat.output_sent($(this).html());
      duke.webchat.send_msg(str);
    });

    $(document).on('click', '#btn-send', function(e) {
      duke.webchat.output_sent();
      duke.webchat.send_msg();
      if (duke.webchat.stt.inUse) {
        duke.webchat.stt.stop();
      }
    });

    $('.duke-message-option').onclick = (function() {
      console.log("ayya")
      var target;
      target = event.target || event.srcElement;
      $(this).toggleClass("hover-fill duke-selected");
      duke.webchat.output_sent(target.innerHTML);
      event.stopImmediatePropagation;
      if (event.stopPropagation) {
        event.stopPropagation();
      } else {
        event.cancelBubble = true;
      }
      duke.webchat.send_msg($(this).data("value"));
    });

    $(document).on('click', '.duke-suggestion', function() {
      var target;
      target = event.target || event.srcElement;
      $(this).toggleClass("hover-fill duke-selected");
      duke.webchat.output_sent(target.innerHTML);
      if (event.stopPropagation) {
        event.stopPropagation();
      } else {
        event.cancelBubble = true;
      }
      duke.webchat.send_msg($(this).data("value"), $(this).data("intent"));
    });

    $(document).on('click', '#btn-mic', function() {
      duke.webchat.stt.trigger();
    });
  });

  class STTHandler {

    constructor(key, region, webchat) {
      this.key = key;
      this.region = region;
      this.webchat = webchat;
      this.inUse = false;
      this.transcript = "";
      this.recognizer = new (SpeechSDK.SpeechRecognizer)(this.speechConfig(), this.audioConfig());
    }
    speechConfig() {
      var speechConfig = SpeechSDK.SpeechConfig.fromSubscription(this.key, this.region);
      speechConfig.speechRecognitionLanguage = "fr-FR";
      speechConfig.setProfanity(SpeechSDK.ProfanityOption.Raw);
      return speechConfig
    }
    audioConfig() {
      return SpeechSDK.AudioConfig.fromDefaultMicrophoneInput();
    }
    start() {
      this.inUse = true;
      $("#btn-mic").toggleClass("send-enabled", true)
      this.timeout = setTimeout(( () => { if (this.inUse){ this.stop()}}), 20000);
      this.recognizer.startContinuousRecognitionAsync();
      this.recognizer.recognizing = ((s, e) => this.display(e));
      this.recognizer.recognized = ((s, e) => this.transcript += e.result.text.replace(/.$/, " "));
    }
    stop() {
      clearTimeout(this.timeout);
      this.recognizer.stopContinuousRecognitionAsync();
      $("#btn-mic").toggleClass("send-enabled", false);
      this.inUse = false;
      this.transcript = ""
      this.webchat.send_msg()
    }
    display(e) {
      if (this.inUse) {
        $("#duke-input").val(this.transcript + " " + e.result.text);
        $("#duke-input").trigger("input");
      }
    }
    trigger() {
      if (this.inUse) {
        this.stop();
      } else {
        this.start();
      }
    }
  }

  class PusherHandler {

    constructor(key, webchat) {
      this.key = key;
      this.webchat = webchat;
      this.cluster = "eu";
    }

    reset() {
      if (this.channel) {
        this.channel.unbind('duke');
      }
      if (this.instance) {
        this.instance.disconnect();
      }
    }

    instanciate(connBack) {
      if (typeof Pusher !== 'undefined') {
        this.instance = new Pusher(this.key, {
                                  cluster: this.cluster
                                  });
        this.channel = this.instance.subscribe(sessionStorage.getItem('duke_id'))
        this.channel.bind('duke', (data => this.webchat.onMsg(data)))
        this.instance.connection.bind('pusher_interval:subscription_succeeded', connBack)
      } else {
        setTimeout(this.instanciate(connBack), 200);
      }
    }
  }
  
  class DukeWebchat{ 

    constructor(account, tenant, pusher_key, azure_key, azure_region) {
      this.account = account 
      this.tenant = tenant 
      this.pusherHandler = new PusherHandler(pusher_key, this)
      this.stt = new STTHandler(azure_key, azure_region, this)
      this.isMobile = /(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|ipad|iris|kindle|Android|Silk|lge |maemo|midp|mmp|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows (ce|phone)|xda|xiino/i.test(navigator.userAgent) || /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(navigator.userAgent.substr(0, 4));
    }

    init = function() {
      if (sessionStorage.getItem('duke-chat')) {
        this.pusherHandler.reset()
        if (sessionStorage.duke_visible) {
          this.pusherHandler.instanciate(this.persist_duke());
        } else {
          this.pusherHandler.instanciate($('.btn-chat').show());
        }
      } else {
        this.create_session();
      }
    };

    create_session = function() {
      $.ajax('/duke_create_session', {
        type: 'post',
        dataType: 'json',
        data: {
          "user_id": this.account,
          "tenant": this.tenant
        },
        success: ((data, status, xhr) => {sessionStorage.setItem('duke_id', data.session_id);
                                          sessionStorage.setItem('assistant_id', data.assistant_id);
                                          this.pusherHandler.instanciate(this.msg_callback());})
      });
    };

    msg_callback = function() {
      setTimeout(( () => this.send_msg("")), 1000);
    };

    onMsg(data) {
      this.integrate_received(data.message);
      if ($(".btn-chat").is(":visible")){
        $(".btn-chat").css("z-index", "-10").hide()
        $('#bottom_left').css("z-index", "10000000").show();
      }
      else if ($('#bottom_left').is(":hidden")){
        $(".btn-chat").css("z-index", "9999999").show()
      }
    }

    send_msg = function(msg = $("#duke-input").val().replace(/\n/g, "") , user_intent = undefined) {
      if (msg.toString().match(cancelationReg)) {
        user_intent = "quick_exit";
      }
      this.reset_textarea();
      this.clear_textarea();
      $.ajax('/duke_send_msg', {
        type: 'post',
        data: {
          "msg": msg,
          "user_intent": user_intent,
          "user_id": this.account,
          "tenant": this.tenant,
          "duke_id": sessionStorage.getItem('duke_id'),
          "assistant_id": sessionStorage.getItem('assistant_id')
        },
        dataType: 'json'
      });
    };

    output_sent = function(msg = $("#duke-input").val().replace(/\n/g, "")) {
      this.disable_buttons();
      if (msg) {
        $('.msg_container_base').append('<div class="msg-list sender msg-sdd"><div class="messenger-container"><p>' + msg + '</p></div></div>');
        $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
      }
    };

    disable_buttons = function() {
      $(".duke-select-wrap").last().parent().remove();
      $(".duke-centered").last().remove();
      if ($('.msg_container_base').children().last().hasClass('options')) {
        $.each($('.msg_container_base').children().last().children(), function(index, option) {
          $(option).prop("disabled", true);
          if (!$(option).hasClass("duke-selected")) {
            return $(option).toggleClass("hover-fill duke-disabled");
          }
        });
      }
    };
    integrate_received = function(data) {
      $.each(data, function(idx, value) {
        var text = value.response_type == "text" ? value.text : value.title;
        var options = value.response_type == "option" ? value.options : value.suggestions;
        new DukeMessage(value.response_type, text, options).display();
      });
    };

    enable_send() {
    if ($("#duke-input").val() == "")
      $('#btn-send').toggleClass("disabled-send", true).toggleClass("send-enabled",false)
    else
      $('#btn-send').toggleClass("disabled-send", false).toggleClass("send-enabled",true)
    return
    }

    persist_duke = function() {
      $('.msg_container_base').append(sessionStorage.getItem('duke-chat'));
      $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
      $('#bottom_left').css("z-index", "10000000").show();
      sessionStorage.removeItem('duke_visible');
    };

    clear_textarea = function() {
      $('#btn-send').toggleClass("disabled-send", true).toggleClass("send-enabled", false);
      $("#duke-input").val("");
    };

    reset_textarea = function() {
      $('#duke-input').css('height', '60px');
      $('.msg_container_base').css('height', $('#bottom_left').height() - $('.input-flex').height() - 45);
    };

    resize = (function() {
      $('.msg_container_base').css('height', $('#bottom_left').height() - $('.input-flex').height() - 45);
    });
  }

  class DukeMessage{
      
    constructor(type, text, options) {
      this.type = type; 
      this.text = text; 
      this.options = options;
    }

    display() {
      this.loading_message();
      setTimeout(( () => {$('#waiting').remove();
                          this.output_received_text();
                          this.output_received_options();
                          this.redirect();}), 700);
    };

    output_received_text() {
      var outputed = this.text.replace(redirectionReg,"").replace(base_urlReg, "")
      $('.duke-received:last p:first').css("border-style", "unset");
      $('.msg_container_base').append('<div class="msg-list msg-rcvd"> <div class="messenger-container duke-received"> <p>' + outputed + '</p> </div> </div>');
      $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
    };

    output_received_options() {
      if (this.options && this.options.length > 0) {
        $('.msg_container_base').append('<div class="msg_container options general"></div>');
        if (multChoicesReg.test(this.text)) {
          this.multiple_options();
        } else {
          if (this.options.length > 7) {
            this.dropdown_options();
          } else {
            this.single_options();
          }
        }
        $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
      }
    };

    multiple_options() {
      $.each(this.options, function(index, op) {
        if (op.hasOwnProperty('global_label')) {
          $('.msg_container.options').last().append('<p class = "duke-multi-label">' + op.global_label + '</p>');
        } else {
          $('.msg_container.options').last().append('<label data-value= \'' + escapeHtml(op.value.input.text) + '\'class="control control--checkbox">' + escapeHtml(op.label) + '<input type="checkbox"/> <div class="control__indicator"></div> </label>');
        }
      });
      $('.msg_container.options').last().append('<div class="msg_container options duke-centered"> <button type="button" class="gb-bordered hover-fill duke-option duke-checkbox-validation duke-validation ">Valider</button> <button type="button" class="gb-bordered hover-fill duke-option duke-cancelation ">Retour</button> </div>');
    };

    single_options() {
      $.each(this.options, function(index, op) {
        if (op.hasOwnProperty('source_dialog_node')) {
          var intent = op.value.input.intents.length == 0 ? "none_of_the_above" : op.value.input.intents[0].intent
          return $('.msg_container.options').last().append('<button type="button" data-value= \'' + escapeHtml(op.value.input.text) + '\'data-intent= \'' + escapeHtml(intent) + '\' class="gb-bordered hover-fill duke-option duke-suggestion ">' + escapeHtml(op.label) + '</button>');
        } else {
          return $('.msg_container.options').last().append('<button type="button" data-value= \'' + escapeHtml(op.value.input.text) + '\' class="gb-bordered hover-fill duke-option duke-message-option">' + escapeHtml(op.label) + '</button>');
        }
      });
    };

    dropdown_option() {
      $('.msg_container.options').last().append('<div class="duke-select-wrap"><ul class="duke-default-option"><li><div class="option"> <p>Choisissez une option</p></div></li></ul><ul class="duke-select-ul"></ul> </div>');
      $.each(this.options, function(index, op) {
        $('.duke-select-ul').last().append('<li data-value= \'' + escapeHtml(op.value.input.text) + '\'><div class="option"> <p>' + escapeHtml(op.label) + '</p></div> </li>');
      });
    };

    redirect() {
      var duke_chat = Array.from($('.msg_container_base').children()).map(msg => msg.outerHTML).join("")
      var redirection = this.text.match(redirectionReg)
      if (redirection) {
        location.replace(base_url + redirection[2]);
        var duke_chat = redirection[1] ? "<div class='messenger-container duke-received'><p>Bienvenue, je vous écoute</p></div>" : duke_chat
        if (redirection[1]) {
          sessionStorage.setItem('duke_visible', true);
        }
      }
      sessionStorage.setItem('duke-chat', duke_chat);
    };

    loading_message() {
      $('.msg_container_base').append('<div class="msg-list msg-rcvd" id="waiting"><div class="messenger-container"> <svg width="38" height="38" viewBox="0 0 38 38" xmlns="http://www.w3.org/2000/svg"><defs><linearGradient x1="8.042%" y1="0%" x2="65.682%" y2="23.865%" id="a"><stop stop-color="black" stop-opacity="0" offset="0%"/><stop stop-color="black" stop-opacity=".631" offset="63.146%"/><stop stop-color="black" offset="100%"/></linearGradient></defs> <g fill="none" fill-rule="evenodd"><g transform="translate(1 1)"><path d="M36 18c0-9.94-8.06-18-18-18" id="Oval-2" stroke="url(#a)" stroke-width="2"><animateTransform attributeName="transform"type="rotate"from="0 18 18"to="360 18 18"dur="0.5s"repeatCount="indefinite" /></path><circle fill="black" cx="36" cy="18" r="1"><animateTransform attributeName="transform"type="rotate"from="0 18 18"to="360 18 18"dur="0.5s"repeatCount="indefinite" /></circle></g></g></svg></div></div>');
      $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
    };
  }
})(ekylibre, jQuery);