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
    instanciate(connBack, intent) {
      this.cable = ActionCable.createConsumer(this.cable_url);
      this.duke_subscription = this.cable.subscriptions.create({
        channel: 'DukeChannel',
        roomId: sessionStorage.getItem('duke_id')
      }, {
        received: function(data) {
          D.webchat_interface.onMsg(data);
        },
        connected: function() {
          connBack.bind(D.webchat)(intent);
        }
      });
    }

  }
  D.DukeActionCableHandler = DukeActionCableHandler;
})(window.Duke = window.Duke || {}, jQuery);