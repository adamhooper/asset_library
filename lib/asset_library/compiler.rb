require File.dirname(__FILE__) + '/compiler/base'
require File.dirname(__FILE__) + '/compiler/default'
require File.dirname(__FILE__) + '/compiler/closure'

class AssetLibrary
  module Compiler
    class << self
      # Create an instance of a compiler for the given compiler type.
      def create(type, config={})
        klass = compiler_classes[type] ||= built_in_class_for(type)
        klass.new(config)
      end

      # Register a custom compiler class.
      def register(type, klass)
        compiler_classes[type] = klass
      end

      def reset!
        compiler_classes.clear
      end

      private

      def compiler_classes
        @compiler_classes ||= {}
      end

      def built_in_class_for(type)
        class_name = type.to_s.gsub(/(?:\A|_)(.)/){$1.upcase}
        const_get(class_name)
      end
    end
  end
end
