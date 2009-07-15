require File.dirname(__FILE__) + '/asset'

class AssetLibrary
  class AssetModule
    attr_reader(:config)

    def initialize(config)
      @config = config
    end

    # Returns an Array of Assets to include.
    #
    # Arguments:
    #   extra_suffix: if set, finds files with the given extra suffix
    def assets(extra_suffix = nil)
      return nil unless config

      ret = []
      config[:files].each do |requested_file|
        ret.concat(assets_for_pattern(requested_file, extra_suffix))
      end
      ret.uniq!
      ret
    end

    def contents(extra_suffix = nil)
      s = StringIO.new

      assets(extra_suffix).each do |asset|
        File.open(asset.absolute_path, 'r') do |infile|
          s.write(infile.read)
        end
      end
      s.rewind

      s
    end

    # Returns an Asset representing the cache file
    def cache_asset(extra_suffix = nil)
      extra = extra_suffix ? ".#{extra_suffix}" : ''
      Asset.new(File.join(AssetLibrary.root, config[:base], "#{config[:cache]}#{extra}.#{config[:suffix]}"))
    end

    def write_cache(extra_suffix = nil)
      File.open(cache_asset(extra_suffix).absolute_path, 'w') do |outfile|
        outfile.write(contents(extra_suffix).read)
      end
    end

    def write_all_caches
      cache_suffixes = [ nil ] + (config[:extra_suffixes] || [])
      cache_suffixes.each do |extra_suffix|
        write_cache(extra_suffix)
      end
    end

    private

    def assets_for_pattern(pattern, extra_suffix)
      ret = []

      suffix = config[:suffix]
      suffix = "#{extra_suffix}.#{suffix}" if extra_suffix

      requested_path = File.join(AssetLibrary.root, config[:base], "#{pattern}.#{suffix}")

      Dir.glob(requested_path).sort.each do |found_file|
        found_file = maybe_add_optional_suffix_to_path(found_file)
        next if path_contains_extra_dot?(found_file, pattern, extra_suffix)
        ret << AssetLibrary::Asset.new(found_file)
      end

      ret
    end

    def maybe_add_optional_suffix_to_path(path)
      if config[:optional_suffix]
        basename = path[0..-(config[:suffix].length + 2)]
        path_with_suffix = "#{basename}.#{config[:optional_suffix]}.#{config[:suffix]}"
        File.exist?(path_with_suffix) ? path_with_suffix : path
      else
        path
      end
    end

    def path_contains_extra_dot?(path, requested_file, extra_suffix)
      allowed_suffixes = []

      allowed_suffixes << "\\.#{Regexp.quote(extra_suffix)}" if extra_suffix
      allowed_suffixes << "(\\.#{Regexp.quote(config[:optional_suffix])})?" if config[:optional_suffix]
      allowed_suffixes << "\\.#{Regexp.quote(config[:suffix])}" if config[:suffix]

      basename = File.basename(path)
      requested_basename = File.basename(requested_file)

      n_dots = requested_basename.count('.')
      basename_regex = (['[^\.]+'] * (n_dots + 1)).join('\.')

      regex =  /^#{basename_regex}#{allowed_suffixes.join}$/

      !(basename =~ regex)
    end
  end
end
