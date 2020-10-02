module Duke
  class Engine < ::Rails::Engine
    initializer 'duke.assets.precompile' do |app|
      app.config.assets.precompile += %w( duke.js )
      puts "app.config.assets.precompile #{app.config.assets.precompile }"
    end
  end
end
