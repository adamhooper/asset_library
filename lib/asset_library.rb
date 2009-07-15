require File.dirname(__FILE__) + '/asset_library/asset_module'
require File.dirname(__FILE__) + '/asset_library/util'

class AssetLibrary
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
      @cache = cache
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
