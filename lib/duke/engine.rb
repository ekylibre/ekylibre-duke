module Duke
  class Engine < ::Rails::Engine
    initializer 'duke.assets.precompile' do |app|
      app.config.assets.precompile += %w[duke.js *.svg *.haml]
    end

    initializer :i18n do |app|
      app.config.i18n.load_path += Dir[Duke::Engine.root.join('config', 'locales', '**', '*.yml')]
    end

    initializer :hack_plugin_stylesheet do
      Rails.root.join('tmp', 'plugins', 'theme-addons', 'themes', 'tekyla', 'plugins.scss').open('a') do |f|
        f.write <<~SCSS
          // Hack for gem-only plugins to inject css (Duke)
          @import "duke.scss";
        SCSS
      end
    end

    initializer :hack_plugin_javascript do
      Rails.root.join('tmp', 'plugins', 'javascript-addons', 'plugins.js.coffee').open('a') do |f|
        f.write('#= require duke')
      end
    end

    initializer :duke_helpers do
      ActionView::Base.send :include, Backend::DukeHelper
    end

  end
end
