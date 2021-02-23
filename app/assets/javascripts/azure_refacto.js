  
 (function() {
    var stop_stt,
      __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };
  
    vars.stt.stt_on = false;
  
    $(document).on('click', '#btn-mic', function(e) {
      var transcript;
      transcript = "";
      if (vars.stt.is_on) {
        stop_stt();
        if ($("#duke-input").val() !== "") {
          output_sent();
          return send_msg();
        }
      } else {
        vars.stt.is_on = true;
        vars.stt_timeout = setTimeout((function() {
          if (vars.stt.is_on) {
            stop_stt();
          }
        }), 20000);
        if (!(__indexOf.call(vars.stt, "speechConfig") >= 0)) {
          vars.stt.speechConfig = SpeechSDK.SpeechConfig.fromSubscription(vars.azure_key, vars.azure_region);
          vars.stt.speechConfig.speechRecognitionLanguage = "fr-FR";
          vars.stt.speechConfig.setProfanity(SpeechSDK.ProfanityOption.Raw);
          vars.stt.audioConfig = SpeechSDK.AudioConfig.fromDefaultMicrophoneInput();
        }
        vars.stt.recognizer = new SpeechSDK.SpeechRecognizer(vars.stt.speechConfig, vars.stt.audioConfig);
        $("#btn-mic").toggleClass("send-enabled", true);
        vars.stt.recognizer.startContinuousRecognitionAsync();
        vars.stt.recognizer.recognizing = function(s, e) {
          var height;
          if (vars.stt.is_on) {
            $("#duke-input").val(transcript + " " + e.result.text);
            $('#duke-input').css('height', 'auto');
            height = $("#duke-input").prop('scrollHeight');
            $('.msg_container_base').css('height', $('#bottom_left').height() - height - 45);
            $('#duke-input').css('height', height + 'px');
            $('.msg_container_base').scrollTop($('.msg_container_base')[0].scrollHeight);
            if (!($("#duke-input").hasClass("send-enabled"))) {
              $('#btn-send').toggleClass("disabled-send", false);
              $("#btn-send").toggleClass("send-enabled", true);
            }
          }
        };
        return vars.stt.recognizer.recognized = function(s, e) {
          transcript += e.result.text.replace(/.$/, " ");
        };
      }
    });
  
    stop_stt = function() {
      clearTimeout(vars.stt_timeout);
      $("#btn-mic").toggleClass("send-enabled", false);
      vars.stt.recognizer.stopContinuousRecognitionAsync(function() {});
      vars.stt.recognizer.close();
      vars.stt.recognizer = void 0;
      vars.stt.is_on = false;
    };
  
  }).call(this);