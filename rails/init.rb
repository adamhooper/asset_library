AssetLibrary.cache = ActionController::Base.perform_caching
AssetLibrary.config_path = File.join(RAILS_ROOT, 'config', 'asset_library.yml')
AssetLibrary.root = File.join(RAILS_ROOT, 'public')
AssetLibrary.app_root = RAILS_ROOT
