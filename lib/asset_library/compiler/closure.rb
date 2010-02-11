require 'shellwords'
require 'tmpdir'

class AssetLibrary
  module Compiler
    class Closure < Base
      def initialize(config)
        super
        config[:closure_path] or
          raise ConfigurationError, "Please set path of closure jar with compiler.closure_path configuration setting"
        config[:java] ||= 'java'
        config[:java_flags] = normalize_java_flags(config[:java_flags])
      end

      def write_all_caches(format = nil)
        command = [config[:java]]
        command.concat(config[:java_flags])
        command << '-jar' << normalize_path(config[:closure_path])
        # Closure can't seem to output to different directories.
        # Output to a temporary location, and move it into place.
        tmpdir = Dir.tmpdir
        command << '--module_output_path_prefix' << "#{tmpdir}/"
        moves = {}
        each_compilation(format) do |asset_module, output, *inputs|
          dependencies = normalize_dependencies(asset_module.config[:dependencies]).join(',')
          command << '--module' << "#{asset_module.name}:#{inputs.size}:#{dependencies}"
          inputs.each do |input|
            command << '--js' << input
          end
          moves["#{tmpdir}/#{asset_module.name}.js"] = output
        end
        system *command
        move_files(moves)
      end

      # This is stubbed in unit tests, along with #system
      def move_files(moves) # :nodoc:
        moves.each do |src, dst|
          FileUtils.mkdir_p File.dirname(dst)
          File.rename(src, dst)
        end
      end

      private

      def normalize_path(value)
        (Pathname(AssetLibrary.app_root) + value).to_s
      end

      def normalize_java_flags(value)
        case value
        when String
          Shellwords.shellwords(value)
        when nil
          []
        else
          value
        end
      end

      def normalize_dependencies(value)
        if value.is_a?(String)
          value.split
        else
          Array(value)
        end
      end
    end
  end
end
