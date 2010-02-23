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
    before do
      @tmpdir = "#{tmp}/tmpdir"
      FileUtils.mkdir_p @tmpdir
      AssetLibrary::Util.stub!(:mktmpdir).and_yield(@tmpdir)
    end

    it("should run each module's files through closure compiler") do
      compiler = self.compiler
      compiler.add_asset_module mock_asset_module('lib1', :format, 'LIB1.js', 'lib1-file1.js')
      compiler.add_asset_module mock_asset_module('lib2', :format, 'LIB2.js', 'lib2-file1.js', 'lib2-file2.js')
      compiler.should_receive(:system).with(*%W"java -jar /PATH/TO/CLOSURE.jar --js_output_file LIB1.js --js lib1-file1.js").and_return(true)
      compiler.should_receive(:system).with(*%W"java -jar /PATH/TO/CLOSURE.jar --js_output_file LIB2.js --js lib2-file1.js --js lib2-file2.js").and_return(true)
      compiler.write_all_caches(:format)
    end

    it('should take the java executable name from the :java configuration option') do
      compiler = compiler(:java => '/PATH/TO/JAVA')
      add_one_compilation(compiler)
      compiler.should_receive(:system).with{ |*args| args.first == '/PATH/TO/JAVA' }.and_return(true)
      compiler.write_all_caches(:format)
    end

    it('should take the path to closure compiler from the :path configuration option') do
      compiler = compiler(:path => '/CLOSURE.jar')
      add_one_compilation(compiler)
      compiler.should_receive(:system).with{ |*args| args[1..2] == ['-jar', '/CLOSURE.jar'] }.and_return(true)
      compiler.write_all_caches(:format)
    end

    it('should interpret the path as relative to the application root') do
      AssetLibrary.app_root = "#{tmp}/app_root"
      compiler = compiler(:path => 'CLOSURE')
      add_one_compilation(compiler)
      compiler.should_receive(:system).with{ |*args| args[1..2] == ['-jar', "#{tmp}/app_root/CLOSURE"] }.and_return(true)
      compiler.write_all_caches(:format)
    end

    it('should pass any configured java_flags to java') do
      compiler = compiler(:java_flags => "-foo -bar")
      add_one_compilation(compiler)
      compiler.should_receive(:system).with{ |*args| args[1..2] == ['-foo', '-bar'] }.and_return(true)
      compiler.write_all_caches(:format)
    end

    it('should accept an Array for java_flags') do
      compiler = compiler(:java_flags => %w"-foo -bar")
      add_one_compilation(compiler)
      compiler.should_receive(:system).with{ |*args| args[1..2] == ['-foo', '-bar'] }.and_return(true)
      compiler.write_all_caches(:format)
    end

    it('should pass any configured flags to the compiler') do
      compiler = compiler(:flags => "--foo --bar")
      add_one_compilation(compiler)
      compiler.should_receive(:system).with{ |*args| args[3..4] == ['--foo', '--bar'] }.and_return(true)
      compiler.write_all_caches(:format)
    end

    it('should add module compiler flags to the compiler command') do
      compiler = self.compiler
      compiler.add_asset_module mock_asset_module('lib1', :format, 'LIB1.js', 'lib1-file1.js', :compiler_flags => ['--foo'])
      compiler.add_asset_module mock_asset_module('lib2', :format, 'LIB2.js', 'lib2-file1.js', :compiler_flags => ['--bar'])
      compiler.should_receive(:system).with(*%W"java -jar /PATH/TO/CLOSURE.jar --foo --js_output_file LIB1.js --js lib1-file1.js").and_return(true)
      compiler.should_receive(:system).with(*%W"java -jar /PATH/TO/CLOSURE.jar --bar --js_output_file LIB2.js --js lib2-file1.js").and_return(true)
      compiler.write_all_caches(:format)
    end

    it('should raise a Compiler::Error if the compiler fails') do
      compiler = self.compiler
      compiler.add_asset_module mock_asset_module('lib1', :format, "lib1.js", "file1.js")
      compiler.stub!(:system).and_return(false)
      lambda{compiler.write_all_caches(:format)}.should raise_error(AssetLibrary::Compiler::Error)
    end
  end
end
