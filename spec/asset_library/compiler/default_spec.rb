require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe(AssetLibrary::Compiler::Default) do
  include TemporaryDirectory
  include CompilerHelpers

  before do
    @compiler = AssetLibrary::Compiler::Default.new(nil)
  end

  describe('#write_all_caches') do
    it('should concatenate each set of input files to produce the respective output files') do
      write_file "lib1-file1.txt", "lib1-file1\n"
      write_file "lib2-file1.txt", "lib2-file1\n"
      write_file "lib2-file2.txt", "lib2-file2\n"
      @compiler.add_asset_module mock_asset_module('lib1', :format, "#{tmp}/lib1.txt", "#{tmp}/lib1-file1.txt")
      @compiler.add_asset_module mock_asset_module('lib2', :format, "#{tmp}/lib2.txt", "#{tmp}/lib2-file1.txt", "#{tmp}/lib2-file2.txt")
      @compiler.write_all_caches(:format)
      File.read("#{tmp}/lib1.txt").should == "lib1-file1\n"
      File.read("#{tmp}/lib2.txt").should == "lib2-file1\nlib2-file2\n"
    end

    def write_file(path, content)
      open("#{tmp}/#{path}", 'w'){|f| f.print content}
    end
  end
end
