require 'shellwords'

class AssetLibrary
  module Util
    class << self
      def symbolize_hash_keys(hash)
        return hash unless Hash === hash # because we recurse
        hash.inject({}) do |ret, (key, value)|
          ret[(key.to_sym rescue key) || key] = symbolize_hash_keys(value)
          ret
        end
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
    end
  end
end
