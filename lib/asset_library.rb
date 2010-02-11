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
      reset!
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
      ret[:asset_library] ||= {}
      ret[:asset_library][:compilers] ||= {}
      @config = cache ? ret : nil
      ret
    end

    def compilers
      @compilers ||= {}
    end

    def asset_module(key)
      module_config = config[key.to_sym]
      if module_config
        AssetModule.new(module_config)
      end
    end

    def compiler(asset_module)
      type = asset_module.compiler_type
      config = self.config[:asset_library][:compilers][type] || {}
      compilers[type] ||= Compiler.create(type, config)
    end

    def cache_keys
      config.keys - [:asset_library]
    end

    def write_all_caches
      cache_keys.each do |key|
        m = asset_module(key)
        c = compiler(m)
        c.add_asset_module(m)
      end

      compilers.values.each do |compiler|
        compiler.write_all_caches
      end
    end

    def delete_all_caches
      asset_modules = cache_keys.collect{|k| AssetLibrary.asset_module(k)}
      asset_modules.each do |m|
        FileUtils.rm_f(m.cache_asset.absolute_path)
      end
    end

    def reset!
      @config = nil
      @cache_vars = nil
      @compilers = nil
      Compiler.reset!
    end
  end
end
