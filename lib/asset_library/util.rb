class AssetLibrary
  module Util
    def self.symbolize_hash_keys(hash)
      return hash unless Hash === hash # because we recurse
      hash.inject({}) do |ret, (key, value)|
        ret[(key.to_sym rescue key) || key] = symbolize_hash_keys(value)
        ret
      end
    end

    # Ruby 1.8.7's Dir.mktmpdir.
    def self.mktmpdir(prefix_suffix=nil, tmpdir=nil)
      case prefix_suffix
      when nil
        prefix = "d"
        suffix = ""
      when String
        prefix = prefix_suffix
        suffix = ""
      when Array
        prefix = prefix_suffix[0]
        suffix = prefix_suffix[1]
      else
        raise ArgumentError, "unexpected prefix_suffix: #{prefix_suffix.inspect}"
      end
      tmpdir ||= Dir.tmpdir
      t = Time.now.strftime("%Y%m%d")
      n = nil
      begin
        path = "#{tmpdir}/#{prefix}#{t}-#{$$}-#{rand(0x100000000).to_s(36)}"
        path << "-#{n}" if n
        path << suffix
        Dir.mkdir(path, 0700)
      rescue Errno::EEXIST
        n ||= 0
        n += 1
        retry
      end

      if block_given?
        begin
          yield path
        ensure
          FileUtils.remove_entry_secure path
        end
      else
        path
      end
    end
  end
end
