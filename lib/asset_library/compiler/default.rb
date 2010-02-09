class AssetLibrary
  module Compiler
    class Default < Base
      def write_all_caches(file_map)
        file_map.each do |output_path, input_paths|
          open(output_path, 'w') do |file|
            input_paths.each do |input_path|
              file << File.read(input_path)
            end
          end
        end
      end
    end
  end
end
