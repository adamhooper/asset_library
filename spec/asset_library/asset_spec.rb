require File.dirname(__FILE__) + '/../spec_helper'

require File.dirname(__FILE__) + '/../../lib/asset_library/asset'

describe(AssetLibrary::Asset) do
  it('should have eql? work for identical assets') do
    a('/a/b.css').should eql(a('/a/b.css'))
  end

  it('should use absolute_path as its hash') do
    a('/a/b.css').hash.should == '/a/b.css'.hash
  end

  context('#relative_path') do
    it('should strip AssetLibrary.root') do
      AssetLibrary.stub!(:root).and_return('/r')
      a('/r/a/b.css').relative_path.should == '/a/b.css'
    end

    it('should strip nothing if root is "/"') do
      AssetLibrary.stub!(:root).and_return('/')
      a('/r/a/b.css').relative_path.should == '/r/a/b.css'
    end
  end

  context('#timestamp') do
    it('should return the file mtime') do
      File.stub!(:mtime).with('/r/a/b.css').and_return(Time.at(123))
      a('/r/a/b.css').timestamp.should == Time.at(123)
    end
  end

  context('#relative_url') do
    before(:each) do
      AssetLibrary.stub!(:root).and_return('/r')
    end

    it('should use relative path and mtime') do
      File.stub!(:mtime).with('/r/a/b.css').and_return(Time.at(123))
      a('/r/a/b.css').relative_url.should == '/a/b.css?123'
    end
  end

  private

  def a(*args)
    AssetLibrary::Asset.new(*args)
  end
end
