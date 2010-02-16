class AssetLibrary
  module Compiler
    class Default < Base
      def write_all_caches(format = nil)
        asset_modules.each do |asset_module|
          open(output_path(asset_module, format), 'w') do |file|
            input_paths(asset_module, format).each do |path|
              file << File.read(path)
            end
          end
        end
      end
    end
  end
end
