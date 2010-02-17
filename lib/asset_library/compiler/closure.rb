require 'shellwords'
require 'tmpdir'

class AssetLibrary
  module Compiler
    class Closure < Base
      def initialize(config)
        super
        config[:path] or
          raise ConfigurationError, "Please set path of closure jar with compilers.closure.path configuration setting"
        config[:java] ||= 'java'
        config[:java_flags] = normalize_flags(config[:java_flags])
        config[:path] = normalize_path(config[:path])
        config[:flags] = normalize_flags(config[:flags])
        config[:compilations] = normalize_compilations(config[:compilations])
      end

      def write_all_caches(format = nil)
        each_compilation_group do |asset_modules, config|
          # Closure can't seem to output to different directories.
          # Output to a temporary location, and move it into place.
          Util.mktmpdir do |tmpdir|
            command = [config[:java]]
            command.concat(config[:java_flags])
            command << '-jar' << config[:path]
            command.concat(config[:flags])
            command << '--module_output_path_prefix' << "#{tmpdir}/"
            moves = {}
            asset_modules.each do |asset_module|
              input_paths = input_paths(asset_module, format)
              dependencies = Array(asset_module.config[:dependencies]).join(',')
              command << '--module' << "#{asset_module.name}:#{input_paths.size}:#{dependencies}"
              input_paths.each do |input|
                command << '--js' << input
              end
              moves["#{tmpdir}/#{asset_module.name}.js"] = output_path(asset_module, format)
            end
            system *command or
              raise Error, "closure compiler failed"
            move_files(moves)
          end
        end
      end

      # This is stubbed in unit tests, along with #system
      def move_files(moves) # :nodoc:
        moves.each do |src, dst|
          FileUtils.mkdir_p File.dirname(dst)
          File.rename(src, dst)
        end
      end

      private

      # Yield groups of asset modules that are to be compiled
      # together.
      def each_compilation_group
        compilations = config[:compilations]
        groups = Array.new(compilations.size){[]}

        compilation_indices = {}
        compilations.each_with_index do |compilation, i|
          compilation[:modules].each { |n| compilation_indices[n] = i }
        end

        asset_modules.each do |asset_module|
          if index = compilation_indices[asset_module.name]
            groups[index] << asset_module
          else
            groups << [asset_module]
          end
        end

        groups.each_with_index do |asset_modules, index|
          next if asset_modules.empty?
          config = self.config.merge(compilations[index] || {})
          yield asset_modules, config
        end
      end

      def normalize_path(path)
        (Pathname(AssetLibrary.app_root) + path).to_s
      end

      def normalize_flags(flags)
        case flags
        when String
          Shellwords.shellwords(flags)
        when nil
          []
        else
          flags
        end
      end

      def normalize_compilations(compilations)
        (compilations || []).map do |compilation|
          normalize_compilation(compilation)
        end
      end

      def normalize_compilation(compilation)
        if compilation.is_a?(Hash)
          compilation[:modules] = Array(compilation[:modules])
          compilation[:path] = normalize_path(compilation[:path]) if compilation[:path]
          compilation[:flags] = normalize_flags(compilation[:flags])
          compilation
        else
          {:modules => Array(compilation)}
        end
      end
    end
  end
end
