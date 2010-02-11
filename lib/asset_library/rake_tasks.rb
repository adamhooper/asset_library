def init_asset_library
  require 'asset_library'

  # TODO: Find a way to not-hard-code these paths?
  AssetLibrary.config_path = File.join(RAILS_ROOT, 'config', 'asset_library.yml')
  AssetLibrary.root = File.join(RAILS_ROOT, 'public')
end

namespace(:asset_library) do
  desc "Writes all asset caches specified in config/asset.yml by concatenating the constituent files."
  task(:write) do
    init_asset_library
    AssetLibrary.write_all_caches
  end

  desc "Deletes all asset caches specified in config/asset.yml"
  task(:clean) do
    init_asset_library
    AssetLibrary.delete_all_caches
  end
end
