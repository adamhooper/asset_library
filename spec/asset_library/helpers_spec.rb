require File.dirname(__FILE__) + '/../spec_helper'

require File.dirname(__FILE__) + '/../../lib/asset_library/helpers'

describe(AssetLibrary::Helpers) do
  before(:each) do
    @h = nil
    AssetLibrary.stub!(:root).and_return('/')
  end
  before(:each) do
    @old_cache = AssetLibrary.cache # Empty globals
  end

  after(:each) do
    @h = nil
  end
  after(:each) do
    AssetLibrary.cache = @old_cache
    @old_cache = nil
  end

  describe('#asset_library_javascript_tags') do
    describe('when not caching') do
      before(:each) do
        AssetLibrary.stub!(:cache).and_return(false)
      end

      it('should fetch using asset_module') do
        m = mock(:assets => [])
        AssetLibrary.should_receive(:asset_module).with(:m).and_return(m)
        h.asset_library_javascript_tags(:m)
      end

      it('should output nothing when a module is empty') do
        m = mock(:assets => [])
        AssetLibrary.stub!(:asset_module).and_return(m)
        h.asset_library_javascript_tags(:m).should == ''
      end

      it('should output a <script> tag for a file') do
        m = mock(:assets => [a('/f.js')])
        AssetLibrary.stub!(:asset_module).and_return(m)
        h.asset_library_javascript_tags(:m).should == '<script type="text/javascript" src="/f.js?123"></script>'
      end

      it('should join <script> tags with newlines') do
        m = mock(:assets => [a('/f.js'), a('/f2.js')])
        AssetLibrary.stub!(:asset_module).and_return(m)
        h.asset_library_javascript_tags(:m).should == '<script type="text/javascript" src="/f.js?123"></script>' + "\n" + '<script type="text/javascript" src="/f2.js?123"></script>'
      end

      it('should use compute_asset_host if available') do
        m = mock(:assets => [a('/f.js')])
        AssetLibrary.stub!(:asset_module).and_return(m)
        h.should_receive(:compute_asset_host).with('/f.js?123').and_return('http://assets.test')
        h.asset_library_javascript_tags(:m).should =~ %r{"http://assets.test/f.js\?123"}
      end

      it('should not use compute_asset_host if it returns nil') do
        m = mock(:assets => [a('/f.js')])
        AssetLibrary.stub!(:asset_module).and_return(m)
        h.should_receive(:compute_asset_host).and_return(nil)
        h.asset_library_javascript_tags(:m).should =~ %r{"/f.js\?123"}
      end

      it('should not use compute_asset_host if it returns ""') do
        m = mock(:assets => [a('/f.js')])
        AssetLibrary.stub!(:asset_module).and_return(m)
        h.should_receive(:compute_asset_host).and_return("")
        h.asset_library_javascript_tags(:m).should =~ %r{"/f.js\?123"}
      end

      it('should add request protocol to compute_asset_host output if applicable') do
        m = mock(:assets => [a('/f.js')])
        AssetLibrary.stub!(:asset_module).and_return(m)
        h.stub!(:compute_asset_host).and_return('assets.test')
        h.instance_variable_set(:@controller, mock(:request => mock(:protocol => 'http://')))
        h.asset_library_javascript_tags(:m).should =~ %r{"http://assets.test/f.js\?123"}
      end
    end

    describe('when caching') do
      before(:each) do
        AssetLibrary.cache = true
      end

      it('should output a single <script> tag with the cache filename') do
        m = mock(:cache_asset => a('/cache.js'))
        AssetLibrary.stub!(:asset_module).and_return(m)
        h.asset_library_javascript_tags(:m).should == '<script type="text/javascript" src="/cache.js?123"></script>'
      end

      it('should use compute_asset_host if available') do
        m = mock(:cache_asset => a('/cache.js'))
        AssetLibrary.stub!(:asset_module).and_return(m)
        h.should_receive(:compute_asset_host).with('/cache.js?123').and_return('http://assets.test')
        h.asset_library_javascript_tags(:m)
        #h.asset_library_javascript_tags(:m).should =~ %r{"http://assets.test/cache.js\?123"}
      end
    end
  end

  describe('#asset_library_stylesheet_tags') do
    describe('when not caching') do
      before(:each) do
        AssetLibrary.stub!(:cache).and_return(false)
      end

      it('should fetch using asset_module') do
        m = mock(:assets => [])
        AssetLibrary.should_receive(:asset_module).with(:m).and_return(m)
        h.asset_library_stylesheet_tags(:m)
      end

      it('should output nothing when a module is empty') do
        m = mock(:assets => [])
        AssetLibrary.stub!(:asset_module).and_return(m)
        h.asset_library_stylesheet_tags(:m).should == ''
      end

      it('should output a single <script> with a single @import when there is one file') do
        m = mock(:assets => [a('/f.css')])
        AssetLibrary.stub!(:asset_module).and_return(m)
        h.asset_library_stylesheet_tags(:m).should == "<style type=\"text/css\">\n@import \"\/f.css?123\";\n</style>"
      end

      it('should use formats to find cache filename') do
        m = mock
        m.should_receive(:assets).with(:e).and_return([a('f.e.css')])
        AssetLibrary.stub!(:asset_module).and_return(m)
        h.asset_library_stylesheet_tags(:m, :e).should == "<style type=\"text/css\">\n@import \"f.e.css?123\";\n</style>"
      end

      it('should output a single <script> tag with 30 @import') do
        m = mock(:assets => (1..30).collect{|i| a("/f#{i}.css") })
        AssetLibrary.stub!(:asset_module).and_return(m)
        h.asset_library_stylesheet_tags(:m).should =~ /\<style type=\"text\/css\"\>(\n@import \"\/f\d+.css\?123\";){30}\n\<\/style\>/
      end

      it('should output two <script> tags with 31 @imports') do
        m = mock(:assets => (1..31).collect{|i| a("/f#{i}.css") })
        AssetLibrary.stub!(:asset_module).and_return(m)
        h.asset_library_stylesheet_tags(:m).should =~ /\<style type="text\/css"\>(\n@import "\/f\d+.css\?123";){30}\n\<\/style\>\n<style type="text\/css"\>\n@import "\/f31.css\?123";\n\<\/style\>/
      end
      
      it('should output a final hash in the parameters as html attributes') do
        m = mock(:assets => [a('/f.css')])
        AssetLibrary.stub!(:asset_module).and_return(m)
        optional_hash = {:key1 => "val1", :key2 => "val2", :key3 => "val3"}
        attributes_to_hash( h.asset_library_stylesheet_tags(:m, optional_hash), [:type] ).should == optional_hash
      end
    end

    describe('when caching') do
      before(:each) do
        AssetLibrary.stub!(:cache).and_return(true)
      end

      it('should output a single <style> tag with the cache filename') do
        m = mock(:cache_asset => a('/cache.css'))
        AssetLibrary.stub!(:asset_module).and_return(m)
        h.asset_library_stylesheet_tags(:m).should == '<link rel="stylesheet" type="text/css" href="/cache.css?123" />'
      end

      it('should use format for the cache filename') do
        m = mock
        m.should_receive(:cache_asset).with(:e).and_return(a('/cache.e.css'))
        AssetLibrary.stub!(:asset_module).and_return(m)
        h.asset_library_stylesheet_tags(:m, :e).should == '<link rel="stylesheet" type="text/css" href="/cache.e.css?123" />'
      end

      it('should output a final hash in the parameters as html attributes') do
        m = mock(:cache_asset => a('/cache.css'))
        AssetLibrary.stub!(:asset_module).and_return(m)
        optional_hash = {:key1 => "val1", :key2 => "val2", :key3 => "val3"}
        attributes_to_hash( h.asset_library_stylesheet_tags(:m, optional_hash), [:type, :rel, :href] ).should == optional_hash
      end
    end
  end

  private

  def a(path)
    File.stub!(:mtime).and_return(Time.at(123))
    AssetLibrary::Asset.new(path)
  end

  def h
    return @h if @h
    c = Class.new do
      include AssetLibrary::Helpers
    end
    @h = c.new
  end
end
