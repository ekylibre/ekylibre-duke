(function (D, $) {
  class DukeSTTHandler {

    constructor(key, region) {
      this.key = key;
      this.region = region;
      this.inUse = false;
      this.transcript = "";
      this.recognizer = new (SpeechSDK.SpeechRecognizer)(this.speechConfig(), this.audioConfig());
    };

    /**
     * @return {speechConfig} speech configuration
     */
    speechConfig() {
      var speechConfig = SpeechSDK.SpeechConfig.fromSubscription(this.key, this.region);
      speechConfig.speechRecognitionLanguage = "fr-FR";
      speechConfig.setProfanity(SpeechSDK.ProfanityOption.Raw);
      return speechConfig
    };

    /**
     * @return {audioConfig} audio configuration
     */
    audioConfig() { 
      return SpeechSDK.AudioConfig.fromDefaultMicrophoneInput();
    };

    /**
     * start Vocal Recognition, output result in textArea
     */
    start() { 
      this.inUse = true;
      D.webchat_interface.$btn_mic.toggleClass("send-enabled", true)
      this.timeout = setTimeout(( () => { if (this.inUse){ this.stop()}}), D.DukeUtils.stt_timeout);
      this.recognizer.startContinuousRecognitionAsync();
      this.recognizer.recognizing = ((s, e) => this.display(e));
      this.recognizer.recognized = ((s, e) => { if (this.inUse){ this.transcript += e.result.text.replace(/.$/, " ")}});
    };

    /**
     * Stop Vocal Recognition, try to send msg
     */
    stop() { 
      clearTimeout(this.timeout);
      this.recognizer.stopContinuousRecognitionAsync();
      D.webchat_interface.$btn_mic.toggleClass("send-enabled", false);
      this.inUse = false;
      this.transcript = "";
      if (D.webchat_interface.$duke_input.val() != "") {
        D.webchat_interface.output_sent();
        D.webchat.send_msg();
      }
    };

    /** 
     * Display text as it arrives 
     * @param {Event} e - Recognizing|Recognized event 
     */
    display(e) { 
      if (this.inUse) {
        D.webchat_interface.$duke_input.val(this.transcript + " " + e.result.text);
        D.webchat_interface.$duke_input.trigger("input").trigger("keyup");
      }
    };

    /**
     * Check recognizer state -> record|stop-recording
     */
    trigger() { 
      if (this.inUse) {
        this.stop();
      } else {
        this.start();
      }
    };
  }
  D.DukeSTTHandler = DukeSTTHandler; 
})(window.Duke = window.Duke || {}, jQuery);