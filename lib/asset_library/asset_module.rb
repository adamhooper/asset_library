require File.dirname(__FILE__) + '/asset'

class AssetLibrary
  class AssetModule
    attr_reader(:config)

    def initialize(name, config)
      @name = name.to_s
      @config = config
    end

    attr_reader :name

    # Returns the type of compiler to use for this asset module.
    def compiler_type
      (config[:compiler] || :default).to_sym
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

    # Returns an Asset representing the cache file
    def cache_asset(format = nil)
      extra = format ? ".#{format}" : ''
      Asset.new(File.join(AssetLibrary.root, config[:base], "#{config[:cache]}#{extra}.#{config[:suffix]}"))
    end
  end
end
