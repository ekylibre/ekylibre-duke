(function (D, $) {
  class DukePusherHandler {

    constructor(key) {
      this.key = key;
      this.cluster = "eu";
    };

    /**
     * Delete Pusher Bindings & Instance
     */
    reset() { 
      if (this.channel) {
        this.channel.unbind('duke');
      }
      if (this.instance) {
        this.instance.disconnect();
      }
    };

    /**
     * Creates Pusher connection & bind to user-Duke-channel
     * @param {Method} connBack - onConnected callBack
     */
    instanciate(connBack) {
      if (typeof Pusher !== 'undefined') {
        this.instance = new Pusher(this.key, {cluster: this.cluster});
        this.channel = this.instance.subscribe(sessionStorage.getItem('duke_id'))
        this.channel.bind('duke', (data => D.webchat.onMsg(data)))
        this.instance.connection.bind('pusher_interval:subscription_succeeded', connBack)
      } else {
        setTimeout(( () => this.instanciate(connBack)), 200);
      }
    };
  }
  D.DukePusherHandler = DukePusherHandler;
})(window.Duke = window.Duke || {}, jQuery);