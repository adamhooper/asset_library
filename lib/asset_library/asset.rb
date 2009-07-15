class AssetLibrary
  class Asset
    attr_reader(:absolute_path)

    def initialize(absolute_path)
      @absolute_path = absolute_path
    end

    def eql?(other)
      self.class === other && absolute_path == other.absolute_path
    end

    def hash
      self.absolute_path.hash
    end

    def relative_path
      if AssetLibrary.root == '/'
        absolute_path
      else
        absolute_path[AssetLibrary.root.length..-1]
      end
    end

    def timestamp
      File.mtime(absolute_path)
    end

    def relative_url
      "#{relative_path}?#{timestamp.to_i.to_s}"
    end
  end
end
