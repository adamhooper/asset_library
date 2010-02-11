require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe(AssetLibrary::Compiler::Closure) do
  include TemporaryDirectory
  include CompilerHelpers

  before do
    AssetLibrary.root = "#{tmp}/root"
    AssetLibrary.app_root = "#{tmp}/app_root"
  end

  def compiler(configuration = {})
    configuration[:closure_path] = '/PATH/TO/CLOSURE.jar' unless configuration.key?(:closure_path)
    compiler = AssetLibrary::Compiler::Closure.new(configuration)
    compiler.stub!(:system)
    compiler.stub!(:move_files)
    compiler
  end

  describe('#initialize') do
    it('should cry if the path to the compiler is not set') do
      lambda{compiler(:closure_path => nil)}.should raise_error(AssetLibrary::ConfigurationError)
    end
  end

  describe('#write_all_caches') do
    it('should run the files through closure compiler in one pass as individual modules') do
      compiler = self.compiler
      compiler.add_asset_module mock_asset_module('lib1', :format, "LIB1.js", "lib1-file1.js")
      compiler.add_asset_module mock_asset_module('lib2', :format, "LIB2.js", "lib2-file1.js", "lib2-file2.js")
      compiler.should_receive(:system).with(*%W"
        java -jar /PATH/TO/CLOSURE.jar --module_output_path_prefix #{Dir.tmpdir}/
        --module lib1:1: --js lib1-file1.js
        --module lib2:2: --js lib2-file1.js --js lib2-file2.js
      ")
      compiler.should_receive(:move_files).with({
        "#{Dir.tmpdir}/lib1.js" => "LIB1.js",
        "#{Dir.tmpdir}/lib2.js" => "LIB2.js",
      })
      compiler.write_all_caches(:format)
    end

    it('should take the java executable name from the :java configuration option') do
      compiler = compiler(:java => '/PATH/TO/JAVA')
      compiler.should_receive(:system).with('/PATH/TO/JAVA', '-jar', '/PATH/TO/CLOSURE.jar', '--module_output_path_prefix', "#{Dir.tmpdir}/")
      compiler.write_all_caches
    end

    it('should take the path to closure compiler from the :closure_path configuration option') do
      compiler = compiler(:closure_path => '/CLOSURE.jar')
      compiler.should_receive(:system).with('java', '-jar', '/CLOSURE.jar', '--module_output_path_prefix', "#{Dir.tmpdir}/")
      compiler.write_all_caches
    end

    it('should interpret the closure_path as relative to the application root') do
      AssetLibrary.app_root = "#{tmp}/app_root"
      compiler = compiler(:closure_path => 'CLOSURE')
      compiler.should_receive(:system).with("java", '-jar', "#{tmp}/app_root/CLOSURE", '--module_output_path_prefix', "#{Dir.tmpdir}/")
      compiler.write_all_caches
    end

    it('should pass any extra java_flags configured to java') do
      compiler = compiler(:java_flags => "-foo -bar")
      compiler.should_receive(:system).with('java', '-foo', '-bar', '-jar', '/PATH/TO/CLOSURE.jar', '--module_output_path_prefix', "#{Dir.tmpdir}/")
      compiler.write_all_caches
    end

    it('should accept an array for java_flags') do
      compiler = compiler(:java_flags => %w"-foo -bar")
      compiler.should_receive(:system).with('java', '-foo', '-bar', '-jar', '/PATH/TO/CLOSURE.jar', '--module_output_path_prefix', "#{Dir.tmpdir}/")
      compiler.write_all_caches
    end

    it('should honor declared dependencies') do
      compiler = self.compiler
      compiler.add_asset_module mock_asset_module('lib1', :format, "lib1.js", "file1.js")
      compiler.add_asset_module mock_asset_module('lib2', :format, "lib2.js", "file2.js", :dependencies => 'lib1')
      compiler.add_asset_module mock_asset_module('lib3', :format, "lib3.js", "file3.js", :dependencies => %w'lib1 lib2')
      compiler.add_asset_module mock_asset_module('lib4', :format, "lib4.js", "file4.js", :dependencies => 'lib2 lib3')
      compiler.should_receive(:system).with(*%W"
        java -jar /PATH/TO/CLOSURE.jar --module_output_path_prefix #{Dir.tmpdir}/
        --module lib1:1: --js file1.js
        --module lib2:1:lib1 --js file2.js
        --module lib3:1:lib1,lib2 --js file3.js
        --module lib4:1:lib2,lib3 --js file4.js
      ")
      compiler.write_all_caches(:format)
    end
  end
end
