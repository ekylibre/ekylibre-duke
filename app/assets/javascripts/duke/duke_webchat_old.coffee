(($, E) ->
  $.getScript 'https://js.pusher.com/7.0/pusher.min.js'
  $(document).behave "load", "duke[data-current-account]", ->


)(jQuery, ekylibre)
