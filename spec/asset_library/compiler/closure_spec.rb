require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe(AssetLibrary::Compiler::Closure) do
  include TemporaryDirectory

  it('should run the files through closure compiler in one pass as individual modules') do
    compiler = self.compiler
    compiler.add_asset_module mock_asset_module("lib1.js", "lib1-file1.js")
    compiler.add_asset_module mock_asset_module("lib2.js", "lib2-file1.js", "lib2-file2.js")
    compiler.should_receive(:system).with(*%w'
      java -jar PATH/TO/CLOSURE.jar
      --module lib1.js:1 --js lib1-file1.js
      --module lib2.js:2 --js lib2-file1.js --js lib2-file2.js
    ')
    compiler.write_all_caches
  end

  it('should cry if the path to the compiler is not set') do
    lambda{compiler(:closure_path => nil)}.should raise_error(AssetLibrary::ConfigurationError)
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

  def compiler(configuration = {})
    configuration[:closure_path] = 'PATH/TO/CLOSURE.jar' unless configuration.key?(:closure_path)
    AssetLibrary::Compiler::Closure.new(configuration)
  end

  def mock_asset_module(output_path, *input_paths)
    output_asset = mock(:absolute_path => output_path)
    input_assets = input_paths.map{|path| mock(:absolute_path => path)}
    mock(:cache_asset => output_asset, :assets => input_assets)
  end
end
