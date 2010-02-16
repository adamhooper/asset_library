require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe(AssetLibrary::Compiler::Closure) do
  include TemporaryDirectory
  include CompilerHelpers

  before do
    AssetLibrary.root = "#{tmp}/root"
    AssetLibrary.app_root = "#{tmp}/app_root"
  end

  def compiler(configuration = {})
    configuration[:path] = '/PATH/TO/CLOSURE.jar' unless configuration.key?(:path)
    compiler = AssetLibrary::Compiler::Closure.new(configuration)
    compiler.stub!(:system)
    compiler.stub!(:move_files)
    compiler
  end

  def add_one_compilation(compiler)
    compiler.add_asset_module mock_asset_module('lib', :format, 'out.js', 'in.js')
  end

  describe('#initialize') do
    it('should cry if the path to the compiler is not set') do
      lambda{compiler(:path => nil)}.should raise_error(AssetLibrary::ConfigurationError)
    end
  end

  describe('#write_all_caches') do
    it("should run each module's files through closure compiler") do
      compiler = self.compiler
      compiler.add_asset_module mock_asset_module('lib1', :format, 'LIB1.js', 'lib1-file1.js')
      compiler.add_asset_module mock_asset_module('lib2', :format, 'LIB2.js', 'lib2-file1.js', 'lib2-file2.js')
      compiler.should_receive(:system).with(*%W"java -jar /PATH/TO/CLOSURE.jar --module_output_path_prefix #{Dir.tmpdir}/ --module lib1:1: --js lib1-file1.js")
      compiler.should_receive(:move_files).with("#{Dir.tmpdir}/lib1.js" => "LIB1.js")
      compiler.should_receive(:system).with(*%W"java -jar /PATH/TO/CLOSURE.jar --module_output_path_prefix #{Dir.tmpdir}/ --module lib2:2: --js lib2-file1.js --js lib2-file2.js")
      compiler.should_receive(:move_files).with("#{Dir.tmpdir}/lib2.js" => "LIB2.js")
      compiler.write_all_caches(:format)
    end

    it('should take the java executable name from the :java configuration option') do
      compiler = compiler(:java => '/PATH/TO/JAVA')
      add_one_compilation(compiler)
      compiler.should_receive(:system).with{ |*args| args.first == '/PATH/TO/JAVA' }
      compiler.write_all_caches(:format)
    end

    it('should take the path to closure compiler from the :path configuration option') do
      compiler = compiler(:path => '/CLOSURE.jar')
      add_one_compilation(compiler)
      compiler.should_receive(:system).with{ |*args| args[1..2] == ['-jar', '/CLOSURE.jar'] }
      compiler.write_all_caches(:format)
    end

    it('should interpret the path as relative to the application root') do
      AssetLibrary.app_root = "#{tmp}/app_root"
      compiler = compiler(:path => 'CLOSURE')
      add_one_compilation(compiler)
      compiler.should_receive(:system).with{ |*args| args[1..2] == ['-jar', "#{tmp}/app_root/CLOSURE"] }
      compiler.write_all_caches(:format)
    end

    it('should pass any configured java_flags to java') do
      compiler = compiler(:java_flags => "-foo -bar")
      add_one_compilation(compiler)
      compiler.should_receive(:system).with{ |*args| args[1..2] == ['-foo', '-bar'] }
      compiler.write_all_caches(:format)
    end

    it('should accept an Array for java_flags') do
      compiler = compiler(:java_flags => %w"-foo -bar")
      add_one_compilation(compiler)
      compiler.should_receive(:system).with{ |*args| args[1..2] == ['-foo', '-bar'] }
      compiler.write_all_caches(:format)
    end

    it('should pass any configured flags to the compiler') do
      compiler = compiler(:flags => "--foo --bar")
      add_one_compilation(compiler)
      compiler.should_receive(:system).with{ |*args| args[3..4] == ['--foo', '--bar'] }
      compiler.write_all_caches(:format)
    end

    it('should honor declared dependencies') do
      compiler = self.compiler
      compiler.add_asset_module mock_asset_module('lib1', :format, "lib1.js", "file1.js")
      compiler.add_asset_module mock_asset_module('lib2', :format, "lib2.js", "file2.js", :dependencies => 'lib1')
      compiler.add_asset_module mock_asset_module('lib3', :format, "lib3.js", "file3.js", :dependencies => %w'lib1 lib2')
      compiler.add_asset_module mock_asset_module('lib4', :format, "lib4.js", "file4.js", :dependencies => 'lib2 lib3')
      compiler.should_receive(:system).with(*%W"java -jar /PATH/TO/CLOSURE.jar --module_output_path_prefix #{Dir.tmpdir}/ --module lib1:1:          --js file1.js")
      compiler.should_receive(:system).with(*%W"java -jar /PATH/TO/CLOSURE.jar --module_output_path_prefix #{Dir.tmpdir}/ --module lib2:1:lib1      --js file2.js")
      compiler.should_receive(:system).with(*%W"java -jar /PATH/TO/CLOSURE.jar --module_output_path_prefix #{Dir.tmpdir}/ --module lib3:1:lib1,lib2 --js file3.js")
      compiler.should_receive(:system).with(*%W"java -jar /PATH/TO/CLOSURE.jar --module_output_path_prefix #{Dir.tmpdir}/ --module lib4:1:lib2,lib3 --js file4.js")
      compiler.write_all_caches(:format)
    end

    it('should compile modules together according to configured compilations, and compile the remainder individually') do
      compiler = self.compiler(:compilations => ['lib1 lib3', 'lib4'])
      compiler.add_asset_module mock_asset_module('lib1', :format, "lib1.js", "file1.js")
      compiler.add_asset_module mock_asset_module('lib2', :format, "lib2.js", "file2.js")
      compiler.add_asset_module mock_asset_module('lib3', :format, "lib3.js", "file3.js")
      compiler.add_asset_module mock_asset_module('lib4', :format, "lib4.js", "file4.js")
      compiler.should_receive(:system).with(*%W"java -jar /PATH/TO/CLOSURE.jar --module_output_path_prefix #{Dir.tmpdir}/ --module lib1:1: --js file1.js --module lib3:1: --js file3.js")
      compiler.should_receive(:system).with(*%W"java -jar /PATH/TO/CLOSURE.jar --module_output_path_prefix #{Dir.tmpdir}/ --module lib2:1: --js file2.js")
      compiler.should_receive(:system).with(*%W"java -jar /PATH/TO/CLOSURE.jar --module_output_path_prefix #{Dir.tmpdir}/ --module lib4:1: --js file4.js")
      compiler.write_all_caches(:format)
    end

    it('should support setting per-compilation closure flags') do
      compiler = self.compiler(:compilations => [{:modules => 'lib1', :flags => '--foo --bar'}, {:modules => 'lib2', :flags => '--baz'}])
      compiler.add_asset_module mock_asset_module('lib1', :format, "lib1.js", "file1.js")
      compiler.add_asset_module mock_asset_module('lib2', :format, "lib2.js", "file2.js")
      compiler.should_receive(:system).with(*%W"java -jar /PATH/TO/CLOSURE.jar --foo --bar --module_output_path_prefix #{Dir.tmpdir}/ --module lib1:1: --js file1.js")
      compiler.should_receive(:system).with(*%W"java -jar /PATH/TO/CLOSURE.jar --baz --module_output_path_prefix #{Dir.tmpdir}/ --module lib2:1: --js file2.js")
      compiler.write_all_caches(:format)
    end

    it('should use global compiler configuration where no per-compilation closure flags are given') do
      compiler = self.compiler(:flags => '--global', :compilations => ['lib1', {:modules => 'lib2', :flags => '--local'}])
      compiler.add_asset_module mock_asset_module('lib1', :format, 'lib1.js', 'file1.js')
      compiler.add_asset_module mock_asset_module('lib2', :format, 'lib1.js', 'file2.js')
      compiler.should_receive(:system).with(*%W"java -jar /PATH/TO/CLOSURE.jar --global --module_output_path_prefix #{Dir.tmpdir}/ --module lib1:1: --js file1.js")
      compiler.should_receive(:system).with(*%W"java -jar /PATH/TO/CLOSURE.jar --local --module_output_path_prefix #{Dir.tmpdir}/ --module lib2:1: --js file2.js")
      compiler.write_all_caches(:format)
    end

    it('should ignore names in compilations that do not match asset modules') do
      compiler = self.compiler(:compilations => ['lib1 lib3', 'lib4'])
      compiler.add_asset_module mock_asset_module('lib1', :format, "lib1.js", "file1.js")
      compiler.add_asset_module mock_asset_module('lib2', :format, "lib2.js", "file2.js")
      compiler.should_receive(:system).with(*%W"java -jar /PATH/TO/CLOSURE.jar --module_output_path_prefix #{Dir.tmpdir}/ --module lib1:1: --js file1.js")
      compiler.should_receive(:system).with(*%W"java -jar /PATH/TO/CLOSURE.jar --module_output_path_prefix #{Dir.tmpdir}/ --module lib2:1: --js file2.js")
      compiler.write_all_caches(:format)
    end
  end
end
