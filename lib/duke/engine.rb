require_relative '../../config/initializers/strip_x_forwarded_host'
module Duke
  class Engine < ::Rails::Engine
    initializer 'duke.assets.precompile' do |app|
      app.config.assets.precompile += %w[duke.js *.svg *.haml]
    end

    initializer 'duke.development_config', before: :load_environment_config do |app|
      # required with ngrok 3.1.0 https://github.com/inconshreveable/ngrok/issues/879
      app.config.middleware.insert_before(0, StripXForwardedHost)

      app.config.action_cable.disable_request_forgery_protection = true
      app.config.action_controller.forgery_protection_origin_check = false
    end

    initializer :i18n do |app|
      app.config.i18n.load_path += Dir[Duke::Engine.root.join('config', 'locales', '**', '*.yml')]
    end

    initializer :hack_plugin_stylesheet do
      tmp_file = Rails.root.join('tmp', 'plugins', 'theme-addons', 'themes', 'tekyla', 'plugins.scss')
      tmp_file.open('a') do |f|
        import = '@import "duke.scss";'
        f.puts(import) unless tmp_file.open('r').read.include?(import)
      end
    end

    initializer :hack_plugin_javascript do
      tmp_file = Rails.root.join('tmp', 'plugins', 'javascript-addons', 'plugins.js.coffee')
      tmp_file.open('a') do |f|
        import = '#= require duke'
        f.puts(import) unless tmp_file.open('r').read.include?(import)
      end
    end

    initializer :duke_helpers do
      ActionView::Base.send :include, Backend::DukeHelper
    end

  end
end
