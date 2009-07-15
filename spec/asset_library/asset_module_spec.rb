require File.dirname(__FILE__) + '/../spec_helper'

require 'set'
require 'rglob'

describe(AssetLibrary::AssetModule) do
  before(:each) do
    AssetLibrary.stub!(:root).and_return('/')
  end

  describe('#assets') do
    it('should include file1 and file2') do
      files = [ '/c/file1.css', '/c/file2.css' ]
      stub_fs(files)
      m(css_config(:files => ['file1', 'file2'])).assets.collect{|a| a.absolute_path}.should == files
    end

    it('should not include file2 if that does not exist') do
      files = [ '/c/file1.css' ]
      stub_fs(files)
      m(css_config(:files => ['file1', 'file2'])).assets.collect{|a| a.absolute_path}.should == files
    end

    it('should not include other files') do
      files = [ '/c/file1.css', '/c/file2.css' ]
      stub_fs(files)
      m(css_config(:files => ['file1'])).assets.collect{|a| a.absolute_path}.should == [ files.first ]
    end

    it('should glob filenames') do
      files = [ '/c/file1.css', '/c/file2.css', '/c/other_file.css' ]
      stub_fs(files)
      m(css_config(:files => ['file*'])).assets.collect{|a| a.absolute_path}.should == files[0..1]
    end

    it('should glob directories') do
      files = [ '/c/file1.css', '/c/a/file2.css', '/c/b/a/file3.css' ]
      stub_fs(files)
      m(css_config(:files => ['**/file*'])).assets.collect{|a| a.absolute_path}.should == files[1..2]
    end

    it('should use :optional_suffix when appropriate') do
      files = [ '/c/file1.css', '/c/file1.o.css' ]
      stub_fs(files)
      m(css_config(:optional_suffix => 'o', :files => ['file1'])).assets.collect{|a| a.absolute_path}.should == files[1..1]
    end

    it('should not show :optional_suffix file if original is absent') do
      files = [ '/c/file1.o.css' ]
      stub_fs(files)
      m(css_config(:optional_suffix => 'o', :files => ['file1'])).assets.collect{|a| a.absolute_path}.should == []
    end

    it('should ignore :optional_suffix when suffixed file is not present') do
      stub_fs([ '/c/file1.css' ])
      m(css_config(:optional_suffix => 'o', :files => ['file1'])).assets.collect{|a| a.absolute_path}.should == [ '/c/file1.css' ]
    end

    it('should pick files with :extra_suffix') do
      stub_fs([ '/c/file1.e.css' ])
      m(css_config(:files => ['file1'])).assets('e').collect{|a| a.absolute_path}.should == [ '/c/file1.e.css' ]
    end

    it('should ignore non-suffixed files when :extra_suffix is set') do
      stub_fs([ '/c/file1.css' ])
      m(css_config(:files => ['file1'])).assets('e').collect{|a| a.absolute_path}.should == []
    end

    it('should combine :extra_suffix with :optional_suffix') do
      stub_fs([ '/c/file1.e.css', '/c/file1.e.o.css' ])
      m(css_config(:files => ['file1'], :optional_suffix => 'o')).assets('e').collect{|a| a.absolute_path}.should == [ '/c/file1.e.o.css' ]
    end

    it('should ignore too many dots when globbing') do
      stub_fs([ '/c/file1.x.css' ])
      m(css_config(:files => ['file1*'])).assets.collect{|a| a.absolute_path}.should == []
    end

    it('should pick files with :extra_suffix when globbing') do
      stub_fs([ '/c/file1.e.css', '/c/file2.css' ])
      m(css_config(:files => ['file*'])).assets('e').collect{|a| a.absolute_path}.should == [ '/c/file1.e.css' ]
    end

    it('should pick files with :optional_suffix when globbing') do
      stub_fs([ '/c/file.css', '/c/file.o.css' ])
      m(css_config(:optional_suffix => 'o', :files => ['file*'])).assets.collect{|a| a.absolute_path}.should == [ '/c/file.o.css' ]
    end

    it('should pick files with both :extra_suffix and :optional_suffix when globbing') do
      stub_fs([ '/c/file.css', '/c/file.e.css', '/c/file.e.o.css' ])
      m(css_config(:optional_suffix => 'o', :files => ['file*'])).assets('e').collect{|a| a.absolute_path}.should == [ '/c/file.e.o.css' ]
    end
  end

  describe('#contents') do
    it('should return an IO object') do
      stub_fs([ '/c/file1.css', '/c/file2.css' ])
      m(css_config(:files => ['file*'])).contents.should(respond_to(:read))
    end

    it('should concatenate individual file contents') do
      stub_fs([ '/c/file1.css', '/c/file2.css' ])
      m(css_config(:files => ['file*'])).contents.read.should == '/c/file1.css/c/file2.css'
    end
  end

  describe('#cache_asset') do
    it('should use options[:cache]') do
      m(css_config).cache_asset.absolute_path.should == '/c/cache.css'
    end

    it('should use :extra_suffix if set') do
      m(css_config).cache_asset('e').absolute_path.should == '/c/cache.e.css'
    end
  end

  describe('#write_cache') do
    it('should write to cache.css') do
      File.should_receive(:open).with('/c/cache.css', 'w')
      m(css_config).write_cache
    end

    it('should write cache contents to cache') do
      f = StringIO.new
      File.stub!(:open).with('/c/cache.css', 'w').and_yield(f)
      stub_fs([ '/c/file1.css', '/c/file2.css' ])
      m(css_config(:files => ['file*'])).write_cache
      f.rewind
      f.read.should == '/c/file1.css/c/file2.css'
    end

    it('should use :extra_suffix to determine CSS output file') do
      File.should_receive(:open).with('/c/cache.e.css', 'w')
      m(css_config).write_cache('e')
    end
  end

  describe('#write_all_caches') do
    it('should write cache.css (no :extra_suffix)') do
      File.should_receive(:open).with('/c/cache.css', 'w')
      m(css_config).write_all_caches
    end

    it('should write no-extra_suffix and all extra_suffix files') do
      suffixes = [ 'e1', 'e2' ]
      File.should_receive(:open).with('/c/cache.css', 'w')
      suffixes.each do |suffix|
        File.should_receive(:open).with("/c/cache.#{suffix}.css", 'w')
      end
      m(css_config(:extra_suffixes => suffixes)).write_all_caches
    end
  end

  private

  def m(config)
    AssetLibrary::AssetModule.new(config)
  end

  def js_config(options = {})
    {
      :cache => 'cache',
      :base => 'j',
      :suffix => 'js',
      :files => [ 'file1', 'file2' ]
    }.merge(options)
  end

  def css_config(options = {})
    {
      :cache => 'cache',
      :base => 'c',
      :suffix => 'css',
      :files => [ 'file1', 'file2' ]
    }.merge(options)
  end

  def stub_fs(filenames)
    filenames = Set.new(filenames)
    File.stub!(:exist?).and_return do |path|
      filenames.include?(path)
    end

    filenames.each do |path|
      File.stub!(:open).with(path, 'r').and_yield(StringIO.new(path))
    end

    Dir.stub!(:glob).and_return do |path|
      glob = RGlob::Glob.new(path)
      filenames.select { |f| glob.match(f) }
    end
  end
end
