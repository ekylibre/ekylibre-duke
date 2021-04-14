(function (D, $) {

  const base_url = window.location.protocol + '//' + location.host;
  const base_urlReg = new RegExp('#base-url', 'g');
  const cancelationReg = new RegExp('annul', 'i');
  const redirectionReg = /redirect(keep)?=(.{10,})/;
  const multChoicesReg = /=multiple_choices/;
  const pusher_retry = 200;
  const stt_timeout = 30000;
  const isMobile = /(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|ipad|iris|kindle|Android|Silk|lge |maemo|midp|mmp|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows (ce|phone)|xda|xiino/i.test(navigator.userAgent) || /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(navigator.userAgent.substr(0, 4));
  const templates = { // Json object representing HTML partials
    loadingIcon: '<div class="msg-list msg-rcvd" id="waiting"><div class="messenger-container"> <svg width="38" height="38" viewBox="0 0 38 38" xmlns="http://www.w3.org/2000/svg"><defs><linearGradient x1="8.042%" y1="0%" x2="65.682%" y2="23.865%" id="a"><stop stop-color="black" stop-opacity="0" offset="0%"/><stop stop-color="black" stop-opacity=".631" offset="63.146%"/><stop stop-color="black" offset="100%"/></linearGradient></defs> <g fill="none" fill-rule="evenodd"><g transform="translate(1 1)"><path d="M36 18c0-9.94-8.06-18-18-18" id="Oval-2" stroke="url(#a)" stroke-width="2"><animateTransform attributeName="transform"type="rotate"from="0 18 18"to="360 18 18"dur="0.5s"repeatCount="indefinite" /></path><circle fill="black" cx="36" cy="18" r="1"><animateTransform attributeName="transform"type="rotate"from="0 18 18"to="360 18 18"dur="0.5s"repeatCount="indefinite" /></circle></g></g></svg></div></div>',
    opt_container: '<div class="msg_container options general"></div>',
    dropdown: '<div class="duke-select-wrap"><ul class="duke-default-option"><li><div class="option"> <p>Choisissez une option</p></div></li></ul><ul class="duke-select-ul"></ul> </div>',
    mult_validate: '<div class="msg_container options duke-centered"> <button type="button" class="gb-bordered hover-fill duke-option duke-checkbox-validation duke-validation ">Valider</button> <button type="button" class="gb-bordered hover-fill duke-option duke-cancelation ">Retour</button> </div>',
    welcome: "<div class='messenger-container duke-received'><p>Bienvenue, je vous écoute</p></div>",
    msg_sent: (str) => {return '<div class="msg-list sender msg-sdd"><div class="messenger-container"><p>' + str + '</p></div></div>'},
    msg_received: (str) => {return '<div class="msg-list msg-rcvd"> <div class="messenger-container duke-received"> <p>' + str + '</p> </div> </div>'},
    global_label: (str) => {return '<p class = "duke-multi-label">' + str + '</p>'},
    mult_option: (val, label) => {return '<label data-value= \'' + this.escapeHtml(val) + '\'class="control control--checkbox">' + this.escapeHtml(label) + '<input type="checkbox"/> <div class="control__indicator"></div> </label>'},
    suggestion: (op, intent) => {return '<button type="button" data-value= \'' + this.escapeHtml(op.value.input.text) + '\'data-intent= \'' + this.escapeHtml(intent) + '\' class="gb-bordered hover-fill duke-option duke-suggestion ">' + this.escapeHtml(op.label) + '</button>'},
    option: (val, label) => {return '<button type="button" data-value= \'' + this.escapeHtml(val) + '\' class="gb-bordered hover-fill duke-option duke-message-option">' + this.escapeHtml(label) + '</button>'},
    dropdown_opt: (val, label) => {return '<li data-value= \'' + this.escapeHtml(val) + '\'><div class="option"> <p>' + this.escapeHtml(label) + '</p></div> </li>'}
  };

  /**
   * Escapes string to display it inside html Element
   * @param {String} string - String to escape
   * @return {String} str - Escaped string
   */
  escapeHtml = function(string) {
    const toEscape = {'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', '\'': '&#39;', '/': '&#x2F;', '`': '&#x60;','=': '&#x3D;'};
    return String(string).replace(/[&<>"'`=\/]/g, function(s) {
      return toEscape[s];
    });
  };

  class DukeUtils {

    get base_url() {
      return base_url
    }
    
    get stt_timeout() {
    	return stt_timeout
    }
    
    get pusher_retry() {
    	return pusher_retry
    }

    get base_urlReg() {
      return base_urlReg
    }

    get redirectionReg() {
      return redirectionReg
    }

    get cancelationReg() {
      return cancelationReg
    }

    get multChoicesReg() {
      return multChoicesReg
    }

    get isMobile() {
      return isMobile
    }

    get templates() {
      return templates
    }
  }

  D.DukeUtils = new DukeUtils;
})(window.Duke = window.Duke || {}, jQuery);