//= require action_cable
(function (D, $) {
  class DukeActionCableHandler {

    constructor() {
      this.cable_url = "/cable";
    };

    /**
     * Creates ActionCable connection & bind to user-Duke-channel
     * @param {Method} connBack - onConnected callBack
     */
    instanciate(connBack, intent, msg) {
      this.cable = ActionCable.createConsumer(this.cable_url);
      this.duke_subscription = this.cable.subscriptions.create({
        channel: 'DukeChannel',
        roomId: sessionStorage.getItem('duke_id')
      }, {
        received: function(data) {
          console.log("we received a Duke Message")
          D.webchat_interface.onMsg(data);
        },
        connected: function() {
          console.log("correctly connected to DukeChannel")
          connBack.bind(D.webchat)(intent, msg);
          console.log("callBack message has been sent")
        },
        disconnected: function() {
          console.log("we are disconnected from DukeChannel")
        }
      });
    }

  }
  D.DukeActionCableHandler = DukeActionCableHandler;
})(window.Duke = window.Duke || {}, jQuery);