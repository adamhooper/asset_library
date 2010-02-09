require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe(AssetLibrary) do
  before(:each) do
    @old_root = AssetLibrary.root
    @old_config_path = AssetLibrary.config_path
    @old_cache = AssetLibrary.cache
  end

  after(:each) do
    AssetLibrary.root = @old_root
    AssetLibrary.config_path = @old_config_path
    AssetLibrary.cache = @old_cache
  end

  describe('#config') do
    it('should YAML.load_file the config from config_path') do
      AssetLibrary.config_path = '/config.yml'
      File.stub!(:exist?).with('/config.yml').and_return(true)
      YAML.should_receive(:load_file).with('/config.yml')
      AssetLibrary.config
    end

    it('should return {} if config_path does not exist') do
      AssetLibrary.config_path = '/config.yml'
      File.stub!(:exist?).with('/config.yml').and_return(false)
      AssetLibrary.config.should == {}
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

      AssetLibrary.config.should == { :a => { :b => 'c' } }
    end
  end

  describe('#asset_module') do
    before(:each) do
      @config = {}
      AssetLibrary.stub!(:config).and_return(@config)
    end

    it('should return nil when given an invalid key') do
      AssetLibrary.asset_module(:foo).should == nil
    end

    it('should return an AssetModule when given a valid key') do
      @config[:foo] = {}
      AssetLibrary.asset_module(:foo).should(be_a(AssetLibrary::AssetModule))
    end
  end

  describe('#write_all_caches') do
    it('should call write_all_caches on all asset_modules') do
      mock1 = mock
      mock2 = mock

      mock1.should_receive(:write_all_caches)
      mock2.should_receive(:write_all_caches)

      AssetLibrary.stub!(:asset_module).with(:mock1).and_return(mock1)
      AssetLibrary.stub!(:asset_module).with(:mock2).and_return(mock2)

      AssetLibrary.stub!(:config).and_return({ :mock1 => {}, :mock2 => {} })

      AssetLibrary.write_all_caches
    end
  end
end
