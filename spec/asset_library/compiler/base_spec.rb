require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe(AssetLibrary::Compiler::Base) do
  describe('#write_all_caches') do
    it('should raise NotImplementedError') do
      lambda do
        AssetLibrary::Compiler::Base.new({}).write_all_caches
      end.should raise_error(NotImplementedError)
    end
  end
end
