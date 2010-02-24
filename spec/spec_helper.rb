require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../lib/asset_library'

module TemporaryDirectory
  TMP = File.expand_path(File.dirname(__FILE__) + '/tmp')

  def self.included(base)
    base.before do
      remove_tmp
      make_tmp
      enter_tmp
    end

    base.after do
      leave_tmp
      remove_tmp
    end
  end

  def make_tmp
    FileUtils.mkdir_p tmp
  end

  def remove_tmp
    FileUtils.rm_rf tmp
  end

  def enter_tmp
    @original_pwd = Dir.pwd
    Dir.chdir tmp
  end

  def leave_tmp
    Dir.chdir @original_pwd
  end

  def tmp
    TMP
  end
end

module CompilerHelpers
  def mock_asset_module(name, format, output_path, *input_paths)
    config = input_paths.last.is_a?(Hash) ? input_paths.pop : {}
    output_asset = mock(:absolute_path => output_path)
    input_assets = input_paths.map{|path| mock(:absolute_path => path)}
    asset_module = mock(:name => name)
    asset_module.stub!(:cache_asset).with(format).and_return(output_asset)
    asset_module.stub!(:assets).with(format).and_return(input_assets)
    asset_module.stub!(:compiler_flags).and_return(config[:compiler_flags] || [])
    asset_module.stub!(:config).and_return(config)
    asset_module
  end
end

Spec::Runner.configure do |config|
  config.before do
    @old_app_root = AssetLibrary.app_root
    @old_root = AssetLibrary.root
    @old_config_path = AssetLibrary.config_path
    @old_cache = AssetLibrary.cache
  end

  config.after do
    AssetLibrary.app_root = @app_root
    AssetLibrary.root = @old_root
    AssetLibrary.config_path = @old_config_path
    AssetLibrary.cache = @old_cache
    AssetLibrary.reset!
  end
end
