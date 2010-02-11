class AssetLibrary
  module Compiler
    class Base
      def initialize(config)
        @config = config || {}
        @asset_modules = []
      end

      attr_reader :config, :asset_modules

      def add_asset_module(asset_module)
        @asset_modules << asset_module
      end

      def write_all_caches(format = nil)
        raise "abstract method called"
      end

      protected

      # Yields each output path along with its input paths, all
      # absolute.
      def each_compilation(format = nil)
        @asset_modules.each do |asset_module|
          output_path = asset_module.cache_asset(format).absolute_path
          input_paths = asset_module.assets(format).map{|asset| asset.absolute_path}
          yield asset_module.config, output_path, *input_paths
        end
      end
    end
  end
end
