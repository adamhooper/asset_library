require 'tmpdir'

class AssetLibrary
  module Compiler
    class Closure < Base
      def initialize(config)
        super
        config[:path] or
          raise ConfigurationError, "Please set path of closure jar with compilers.closure.path configuration setting"
        config[:java] ||= 'java'
        config[:java_flags] = Util.normalize_flags(config[:java_flags])
        config[:path] = normalize_path(config[:path])
        config[:flags] = Util.normalize_flags(config[:flags])
      end

      def write_all_caches(format = nil)
        asset_modules.each do |asset_module|
          command = [config[:java]]
          command.concat(config[:java_flags])
          command << '-jar' << config[:path]
          command.concat(config[:flags])
          command.concat(asset_module.compiler_flags)
          command << '--js_output_file' << "#{output_path(asset_module, format)}"
          input_paths(asset_module, format).each do |input|
            command << '--js' << input
          end
          system *command or
            raise Error, "closure compiler failed"
        end
      end

      private

      def normalize_path(path)
        (Pathname(AssetLibrary.app_root) + path).to_s
      end
    end
  end
end
