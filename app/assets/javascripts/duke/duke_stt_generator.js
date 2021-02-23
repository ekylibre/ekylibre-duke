(function (E, $) {
  class DukeSTTGenerator {

    constructor(key, region, webchat) {
      this.key = key;
      this.region = region;
      this.webchat = webchat;
      this.inUse = false;
      this.transcript = "";
      this.timeout = undefined;
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
})(ekylibre, jQuery);