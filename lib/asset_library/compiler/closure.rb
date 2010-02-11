require 'shellwords'

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
        each_compilation(format) do |config, output, *inputs|
          dependencies = normalize_dependencies(config[:dependencies]).join(',')
          command << '--module' << "#{output}:#{inputs.size}:#{dependencies}"
          inputs.each do |input|
            command << '--js' << input
          end
        end
        system *command
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
