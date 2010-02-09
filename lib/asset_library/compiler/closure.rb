require 'shellwords'

class AssetLibrary
  module Compiler
    class Closure < Base
      def initialize(config)
        super
        config[:closure_path] or
          raise ConfigurationError, "Please set path of closure jar with compiler.closure_path configuration setting"
        config[:java_path] ||= 'java'
        config[:java_flags] = normalize_java_flags(config[:java_flags])
      end

      def write_all_caches(file_map)
        command = [config[:java_path]]
        command.concat(config[:java_flags])
        command << '-jar' << config[:closure_path]
        # Sort so the order is predictable.
        file_map.sort.each do |output_path, input_paths|
          command << '--module' << "#{output_path}:#{input_paths.size}"
          input_paths.each do |input_path|
            command << '--js' << input_path
          end
        end
        system *command
      end

      private

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
    end
  end
end
