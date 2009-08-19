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
    def assets(format = nil)
      if format
        assets_with_format(format)
      else
        assets_with_extra_suffix(nil)
      end
    end

    # Returns an Array of Assets to include.
    #
    # Arguments:
    #   extra_suffix: if set, finds files with the given extra suffix
    def assets_with_extra_suffix(extra_suffix)
      return nil unless config

      GlobFu.find(
        config[:files],
        :suffix => config[:suffix],
        :extra_suffix => extra_suffix,
        :root => File.join(*([AssetLibrary.root, config[:base]].compact)),
        :optional_suffix => config[:optional_suffix]
      ).collect { |f| Asset.new(f) }
    end

    # Returns an Array of Assets to include.
    #
    # Calls assets_with_extra_suffix for each suffix in the given format
    #
    # Arguments:
    #   format: format specified in the config
    def assets_with_format(format)
      return nil unless config

      extra_suffixes = config[:formats][format.to_sym]
      extra_suffixes.inject([]) { |r, s| r.concat(assets_with_extra_suffix(s)) }
    end

    def contents(format = nil)
      s = StringIO.new

      assets(format).each do |asset|
        File.open(asset.absolute_path, 'r') do |infile|
          s.write(infile.read)
        end
      end
      s.rewind

      s
    end

    # Returns an Asset representing the cache file
    def cache_asset(format = nil)
      extra = format ? ".#{format}" : ''
      Asset.new(File.join(AssetLibrary.root, config[:base], "#{config[:cache]}#{extra}.#{config[:suffix]}"))
    end

    def write_cache(format = nil)
      File.open(cache_asset(format).absolute_path, 'w') do |outfile|
        outfile.write(contents(format).read)
      end
    end

    def write_all_caches
      write_cache
      (config[:formats] || {}).keys.each do |format|
        write_cache(format)
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

      allowed_suffixes << "\\.#{Regexp.quote(extra_suffix.to_s)}" if extra_suffix
      allowed_suffixes << "(\\.#{Regexp.quote(config[:optional_suffix].to_s)})?" if config[:optional_suffix]
      allowed_suffixes << "\\.#{Regexp.quote(config[:suffix].to_s)}" if config[:suffix]

      basename = File.basename(path)
      requested_basename = File.basename(requested_file)

      n_dots = requested_basename.count('.')
      basename_regex = (['[^\.]+'] * (n_dots + 1)).join('\.')

      regex =  /^#{basename_regex}#{allowed_suffixes.join}$/

      !(basename =~ regex)
    end
  end
end
