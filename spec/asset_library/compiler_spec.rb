require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe(AssetLibrary::Compiler) do
  Compiler = AssetLibrary::Compiler

  describe('.create') do
    it('should return a Default compiler for :default') do
      Compiler.create(:default).should be_a(Compiler::Default)
    end

    it('should return a Closure compiler for :closure') do
      Compiler.create(:closure, :closure_path => '').should be_a(Compiler::Closure)
    end

    it('should pass the configuration to the compiler') do
      Compiler.create(:default, {:param => 2}).config[:param].should == 2
    end
  end

  describe('.register') do
    TestCompiler = Class.new(Compiler::Base)

    it('should register a custom compiler type') do
      Compiler.register(:test, TestCompiler)
      compiler = Compiler.create(:test)
      compiler.should be_a(TestCompiler)
    end
  end
end
