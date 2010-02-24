require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe(AssetLibrary) do
  def config_skeleton
    {:modules => {}, :compilers => {}}
  end

  describe('#config') do
    it('should YAML.load_file the config from config_path') do
      AssetLibrary.config_path = '/config.yml'
      File.stub!(:exist?).with('/config.yml').and_return(true)
      YAML.should_receive(:load_file).with('/config.yml')
      AssetLibrary.config
    end

    it('should return a skeletal configuration if config_path does not exist') do
      AssetLibrary.config_path = '/config.yml'
      File.stub!(:exist?).with('/config.yml').and_return(false)
      AssetLibrary.config.should == config_skeleton
    end

    it('should cache config if cache is set') do
      AssetLibrary.cache = true
      AssetLibrary.config_path = '/config.yml'

      File.stub!(:exist?).with('/config.yml').and_return(true)
      YAML.should_receive(:load_file).with('/config.yml').once

      AssetLibrary.config
      AssetLibrary.config
    end

    it('should not cache config if cache is not set') do
      AssetLibrary.cache = false
      AssetLibrary.config_path = '/config.yml'

      File.stub!(:exist?).with('/config.yml').and_return(true)
      YAML.should_receive(:load_file).with('/config.yml').twice

      AssetLibrary.config
      AssetLibrary.config
    end

    it('should symbolize config hash keys') do
      AssetLibrary.cache = false
      AssetLibrary.config_path = '/config.yml'

      File.stub!(:exist?).with('/config.yml').and_return(true)
      YAML.should_receive(:load_file).with('/config.yml').and_return(
        { 'a' => { 'b' =>  'c' } }
      )

      AssetLibrary.config.should == config_skeleton.merge(:a => {:b => 'c'})
    end

    it('should accept a v0.4 config file with a deprecation warning') do
      AssetLibrary.cache = false
      AssetLibrary.config_path = '/config.yml'

      File.stub!(:exist?).with('/config.yml').and_return(true)
      YAML.should_receive(:load_file).with('/config.yml').and_return(
        { 'a' => { 'files' => ['a.js'] } }
      )
      AssetLibrary.should_receive(:warn)

      AssetLibrary.config.should == { :compilers => {}, :modules => { :a => { :files => ['a.js'] } } }
    end
  end

  describe('#asset_module') do
    before(:each) do
      @config = config_skeleton
      AssetLibrary.stub!(:config).and_return(@config)
    end

    it('should return nil when given an invalid key') do
      AssetLibrary.asset_module(:foo).should == nil
    end

    it('should return an AssetModule when given a valid key') do
      @config[:modules][:foo] = {}
      AssetLibrary.asset_module(:foo).should(be_a(AssetLibrary::AssetModule))
    end
  end

  describe('#compiler') do
    include TemporaryDirectory

    before do
      AssetLibrary.app_root = "#{tmp}/root"
    end

    it('should return a Default compiler if no compiler type has been configured for the given asset module') do
      configure_compilers
      asset_module = mock(:compiler_type => :default)
      AssetLibrary.compiler(asset_module).should be_a(AssetLibrary::Compiler::Default)
    end

    it('should return a compiler of the configured type for the given asset module, if one is given') do
      configure_compilers
      asset_module = mock(:compiler_type => :closure)
      AssetLibrary.compiler(asset_module).should be_a(AssetLibrary::Compiler::Closure)
    end

    it('should pass the right compiler configuration to the compiler') do
      config = {:default => {:foo => 2}}
      configure_compilers(config)
      asset_module = mock(:compiler_type => :default)
      AssetLibrary.compiler(asset_module).config[:foo].should == 2
    end

    def configure_compilers(config=nil)
      config = {:compilers => config || {:closure => {:path => 'closure.jar'}}}
      config_path = "#{tmp}/config.yml"
      open(config_path, 'w'){|f| YAML.dump(config, f)}
      AssetLibrary.config_path = config_path
      AssetLibrary.config
    end
  end
end
