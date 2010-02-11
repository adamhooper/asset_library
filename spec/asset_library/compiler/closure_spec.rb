require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe(AssetLibrary::Compiler::Closure) do
  include TemporaryDirectory
  include CompilerHelpers

  def compiler(configuration = {})
    configuration[:closure_path] = 'PATH/TO/CLOSURE.jar' unless configuration.key?(:closure_path)
    AssetLibrary::Compiler::Closure.new(configuration)
  end

  describe('#initialize') do
    it('should cry if the path to the compiler is not set') do
      lambda{compiler(:closure_path => nil)}.should raise_error(AssetLibrary::ConfigurationError)
    end
  end

  describe('#write_all_caches') do
    it('should run the files through closure compiler in one pass as individual modules') do
      compiler = self.compiler
      compiler.add_asset_module mock_asset_module(:format, "lib1.js", "lib1-file1.js")
      compiler.add_asset_module mock_asset_module(:format, "lib2.js", "lib2-file1.js", "lib2-file2.js")
      compiler.should_receive(:system).with(*%w'
        java -jar PATH/TO/CLOSURE.jar
        --module lib1.js:1: --js lib1-file1.js
        --module lib2.js:2: --js lib2-file1.js --js lib2-file2.js
      ')
      compiler.write_all_caches(:format)
    end

    it('should take the path to java from the :java_path configuration option') do
      compiler = compiler(:java_path => 'PATH/TO/JAVA')
      compiler.should_receive(:system).with('PATH/TO/JAVA', '-jar', 'PATH/TO/CLOSURE.jar')
      compiler.write_all_caches
    end

    it('should pass any extra java_flags configured to java') do
      compiler = compiler(:java_flags => "-foo -bar")
      compiler.should_receive(:system).with('java', '-foo', '-bar', '-jar', 'PATH/TO/CLOSURE.jar')
      compiler.write_all_caches
    end

    it('should accept an array for java_flags') do
      compiler = compiler(:java_flags => %w"-foo -bar")
      compiler.should_receive(:system).with('java', '-foo', '-bar', '-jar', 'PATH/TO/CLOSURE.jar')
      compiler.write_all_caches
    end

    it('should honor declared dependencies') do
      compiler = self.compiler
      compiler.add_asset_module mock_asset_module(:format, "lib1.js", "file1.js")
      compiler.add_asset_module mock_asset_module(:format, "lib2.js", "file2.js", :dependencies => 'lib1')
      compiler.add_asset_module mock_asset_module(:format, "lib3.js", "file3.js", :dependencies => %w'lib1 lib2')
      compiler.add_asset_module mock_asset_module(:format, "lib4.js", "file4.js", :dependencies => 'lib2 lib3')
      compiler.should_receive(:system).with(*%w'
        java -jar PATH/TO/CLOSURE.jar
        --module lib1.js:1: --js file1.js
        --module lib2.js:1:lib1 --js file2.js
        --module lib3.js:1:lib1,lib2 --js file3.js
        --module lib4.js:1:lib2,lib3 --js file4.js
      ')
      compiler.write_all_caches(:format)
    end
  end
end
