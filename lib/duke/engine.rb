module Duke
  class Engine < ::Rails::Engine
    initializer 'duke.assets.precompile' do |app|
      app.config.assets.precompile += %w[duke.js *.svg *.haml]
    end

    initializer :i18n do |app|
      app.config.i18n.load_path += Dir[Duke::Engine.root.join('config', 'locales', '**', '*.yml')]
    end

    initializer :hack_plugin_stylesheet do
      tmp_file = Rails.root.join('tmp', 'plugins', 'theme-addons', 'themes', 'tekyla', 'plugins.scss')
      tmp_file.open('a') do |f|
        import = '@import "duke.scss";'
        f.write(import) unless tmp_file.open('r').read.include?(import)
      end
    end

    initializer :hack_plugin_javascript do
      tmp_file = Rails.root.join('tmp', 'plugins', 'javascript-addons', 'plugins.js.coffee')
      tmp_file.open('a') do |f|
        import = '#= require duke'
        f.write(import) unless tmp_file.open('r').read.include?(import)
      end
    end    

    initializer :duke_helpers do
      ActionView::Base.send :include, Backend::DukeHelper
    end

  end
end
