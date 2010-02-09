require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'set'

describe(AssetLibrary::AssetModule) do
  before(:each) do
    AssetLibrary.stub!(:root).and_return(prefix)
  end

  after(:each) do
    wipe_fs
  end

  describe('#assets') do
    it('should include file1 and file2') do
      files = [ '/c/file1.css', '/c/file2.css' ]
      stub_fs(files)
      m(css_config(:files => ['file1', 'file2'])).assets.collect{|a| a.absolute_path}.should == ["#{prefix}/c/file1.css", "#{prefix}/c/file2.css"]
    end

    it('should not include file2 if that does not exist') do
      files = [ '/c/file1.css' ]
      stub_fs(files)
      m(css_config(:files => ['file1', 'file2'])).assets.collect{|a| a.absolute_path}.should == [ "#{prefix}/c/file1.css" ]
    end

    it('should not include other files') do
      files = [ '/c/file1.css', '/c/file2.css' ]
      stub_fs(files)
      m(css_config(:files => ['file1'])).assets.collect{|a| a.absolute_path}.should == [ "#{prefix}/c/file1.css" ]
    end

    it('should glob filenames') do
      files = [ '/c/file1.css', '/c/file2.css', '/c/other_file.css' ]
      stub_fs(files)
      m(css_config(:files => ['file*'])).assets.collect{|a| a.absolute_path}.should == ["#{prefix}/c/file1.css", "#{prefix}/c/file2.css"]
    end

    it('should glob directories') do
      files = [ '/c/file1.css', '/c/a/file2.css', '/c/b/a/file3.css' ]
      stub_fs(files)
      m(css_config(:files => ['**/file*'])).assets.collect{|a| a.absolute_path}.should == ["#{prefix}/c/a/file2.css", "#{prefix}/c/b/a/file3.css", "#{prefix}/c/file1.css"]
    end

    it('should use :optional_suffix when appropriate') do
      files = [ '/c/file1.css', '/c/file1.css.o' ]
      stub_fs(files)
      m(css_config(:optional_suffix => 'o', :files => ['file1'])).assets.collect{|a| a.absolute_path}.should == ["#{prefix}/c/file1.css.o"]
    end

    it('should show :optional_suffix file even if original is absent') do
      files = [ '/c/file1.css.o' ]
      stub_fs(files)
      m(css_config(:optional_suffix => 'o', :files => ['file1'])).assets.collect{|a| a.absolute_path}.should == ["#{prefix}/c/file1.css.o"]
    end

    it('should ignore :optional_suffix when suffixed file is not present') do
      stub_fs([ '/c/file1.css' ])
      m(css_config(:optional_suffix => 'o', :files => ['file1'])).assets.collect{|a| a.absolute_path}.should == [ "#{prefix}/c/file1.css" ]
    end

    it('should pick files with :extra_suffix') do
      stub_fs([ '/c/file1.e.css' ])
      m(css_config(:files => ['file1'])).assets_with_extra_suffix('e').collect{|a| a.absolute_path}.should == [ "#{prefix}/c/file1.e.css" ]
    end

    it('should ignore non-suffixed files when :extra_suffix is set') do
      stub_fs([ '/c/file1.css' ])
      m(css_config(:files => ['file1'])).assets_with_extra_suffix('e').collect{|a| a.absolute_path}.should == []
    end

    it('should use extra suffixes with format') do
      stub_fs([ '/c/file1.e1.css', '/c/file1.e2.css' ])
      m(css_config(:files => ['file1'], :formats => { :f1 => [ 'e1', 'e2' ] })).assets_with_format(:f1).collect{|a| a.absolute_path}.should == [ "#{prefix}/c/file1.e1.css", "#{prefix}/c/file1.e2.css" ]
    end

    it('should ignore extra suffixes unspecified in format') do
      stub_fs([ '/c/file1.e1.css', '/c/file1.e2.css' ])
      m(css_config(:files => ['file1'], :formats => { :f1 => [ 'e1' ] })).assets_with_format(:f1).collect{|a| a.absolute_path}.should == [ "#{prefix}/c/file1.e1.css" ]
    end

    it('should allow nil suffixes in format') do
      stub_fs([ '/c/file1.css', '/c/file1.e1.css' ])
      m(css_config(:files => ['file1'], :formats => { :f1 => [nil, 'e1'] })).assets_with_format(:f1).collect{|a| a.absolute_path}.should == ["#{prefix}/c/file1.css", "#{prefix}/c/file1.e1.css" ]
    end

    it('should combine :extra_suffix with :optional_suffix') do
      stub_fs([ '/c/file1.e.css', '/c/file1.e.css.o' ])
      m(css_config(:files => ['file1'], :optional_suffix => 'o')).assets_with_extra_suffix('e').collect{|a| a.absolute_path}.should == [ "#{prefix}/c/file1.e.css.o" ]
    end

    it('should ignore too many dots when globbing') do
      stub_fs([ '/c/file1.x.css' ])
      m(css_config(:files => ['file1*'])).assets.collect{|a| a.absolute_path}.should == []
    end

    it('should pick files with :extra_suffix when globbing') do
      stub_fs([ '/c/file1.e.css', '/c/file2.css' ])
      m(css_config(:files => ['file*'])).assets_with_extra_suffix('e').collect{|a| a.absolute_path}.should == [ "#{prefix}/c/file1.e.css" ]
    end

    it('should pick files with :optional_suffix when globbing') do
      stub_fs([ '/c/file.css', '/c/file.css.o' ])
      m(css_config(:optional_suffix => 'o', :files => ['file*'])).assets.collect{|a| a.absolute_path}.should == [ "#{prefix}/c/file.css.o" ]
    end

    it('should pick files with both :extra_suffix and :optional_suffix when globbing') do
      stub_fs([ '/c/file.css', '/c/file.e.css', '/c/file.e.css.o' ])
      m(css_config(:optional_suffix => 'o', :files => ['file*'])).assets_with_extra_suffix('e').collect{|a| a.absolute_path}.should == [ "#{prefix}/c/file.e.css.o" ]
    end
  end

  describe('#cache_asset') do
    it('should use options[:cache]') do
      m(css_config).cache_asset.absolute_path.should == "#{prefix}/c/cache.css"
    end

    it('should use :format if set') do
      m(css_config).cache_asset(:e).absolute_path.should == "#{prefix}/c/cache.e.css"
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

  def prefix
    @prefix ||= File.dirname(__FILE__) + '/deleteme'
  end

  def stub_fs(filenames)
    wipe_fs
    FileUtils.mkdir(prefix)

    filenames.each do |file|
      path = File.join(prefix, file)
      dir = File.dirname(path)
      unless File.exist?(dir)
        FileUtils.mkdir_p(dir)
      end
      File.open(path, 'w') { |f| f.write("#{file}\n") }
    end
  end

  def wipe_fs
    if File.exist?(prefix)
      FileUtils.rm_r(prefix)
    end
  end
end
