class AssetLibrary
  module Compiler
    class Base
      def initialize(config)
        @config = config || {}
      end

      attr_reader :config
    end
  end
end
