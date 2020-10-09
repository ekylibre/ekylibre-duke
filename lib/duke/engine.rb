module Duke
  class Engine < ::Rails::Engine
    initializer 'duke.assets.precompile' do |app|
      app.config.assets.precompile += %w( duke.js )
    end

    initializer :i18n do |app|
      app.config.i18n.load_path += Dir[Duke::Engine.root.join('config', 'locales', '**', '*.yml')]
    end

  end
end
