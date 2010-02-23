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
        raise NotImplementedError, "abstract method"
      end

      protected

      # Return the absolute output path for the given asset module.
      def output_path(asset_module, format)
        asset_module.cache_asset(format).absolute_path
      end

      # Return the absolute input paths for the given asset module.
      def input_paths(asset_module, format)
        asset_module.assets(format).map{|asset| asset.absolute_path}
      end
    end
  end
end
