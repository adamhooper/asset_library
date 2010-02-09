begin
  require 'glob_fu'
rescue LoadError
  require 'rubygems'
  require 'glob_fu'
end

require File.dirname(__FILE__) + '/asset_library/compiler'
require File.dirname(__FILE__) + '/asset_library/asset_module'
require File.dirname(__FILE__) + '/asset_library/util'

class AssetLibrary
  ConfigurationError = Class.new(RuntimeError)

  class << self
    def config_path
      @config_path
    end

    def config_path=(config_path)
      @config_path = config_path
    end

    def root
      @root
    end

    def root=(root)
      @root = root
    end

    def cache
      return true if @cache.nil?
      @cache
    end

    def cache=(cache)
      @config = nil
      @cache_vars = nil
      @cache = cache
    end

    def cache_vars
      # We store cache_vars even if not caching--this is our "globals"
      @cache_vars ||= {}
    end

    def config
      return @config if cache && @config
      ret = if File.exist?(config_path)
        yaml = YAML.load_file(config_path) || {}
        Util::symbolize_hash_keys(yaml)
      else
        {}
      end
      @config = cache ? ret : nil
      ret
    end

    def asset_module(key)
      module_config = config[key.to_sym]
      if module_config
        AssetModule.new(module_config)
      end
    end

    def write_all_caches
      config.keys.each do |key|
        m = asset_module(key)
        m.write_all_caches
      end
    end
  end
end
