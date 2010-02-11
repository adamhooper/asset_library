class AssetLibrary
  module Compiler
    class Default < Base
      def write_all_caches(format = nil)
        each_compilation(format) do |asset_module, output, *inputs|
          open(output, 'w') do |file|
            inputs.each do |input|
              file << File.read(input)
            end
          end
        end
      end
    end
  end
end
