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
  def mock_asset_module(format, output_path, *input_paths)
    config = input_paths.last.is_a?(Hash) ? input_paths.pop : {}
    output_asset = mock(:absolute_path => output_path)
    input_assets = input_paths.map{|path| mock(:absolute_path => path)}
    asset_module = mock
    asset_module.stub!(:cache_asset).with(format).and_return(output_asset)
    asset_module.stub!(:assets).with(format).and_return(input_assets)
    asset_module.stub!(:config).and_return(config)
    asset_module
  end
end

Spec::Runner.configure do |config|
  config.before{AssetLibrary.reset!}
end
