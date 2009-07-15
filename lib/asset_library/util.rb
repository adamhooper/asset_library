class AssetLibrary
  module Util
    def self.symbolize_hash_keys(hash)
      return hash unless Hash === hash # because we recurse
      hash.inject({}) do |ret, (key, value)|
        ret[(key.to_sym rescue key) || key] = symbolize_hash_keys(value)
        ret
      end
    end
  end
end
