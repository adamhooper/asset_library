require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe(AssetLibrary) do
  include TemporaryDirectory

  class ReverseCompiler < AssetLibrary::Compiler::Base
    def write_all_caches(format = nil)
      each_compilation(format) do |config, output, *inputs|
        open(output, 'w') do |file|
          inputs.reverse_each do |input|
            file << File.read(input)
          end
        end
      end
    end
  end

  before do
    AssetLibrary::Compiler.register(:reverse, ReverseCompiler)
  end

  it "should generate cached asset libraries for each asset module, with the configured compiler" do
    AssetLibrary.root = "#{tmp}/root"
    write_file "#{tmp}/root/cssbase/stylesheet-1.css", "style1 { background: #000 }"
    write_file "#{tmp}/root/cssbase/stylesheet-2.css.opt", "style2 { background: #fff }"
    write_file "#{tmp}/root/jsbase/javascript-1.js", "function f1(){alert('1');}"
    write_file "#{tmp}/root/jsbase/javascript-2.js.opt", "function f2(){alert('2');}"
    config_path = "#{tmp}/config.yml"
    open(config_path, 'w'){|f| f.puts <<-EOS}
      stylsheets:
        cache: lib
        optional_suffix: opt
        base: cssbase
        suffix: css
        files:
          - stylesheet-1
          - stylesheet-2

      javascripts:
        cache: lib
        optional_suffix: opt
        base: jsbase
        suffix: js
        compiler: reverse
        files:
          - javascript-1
          - javascript-2
    EOS
    AssetLibrary.config_path = config_path
    AssetLibrary.write_all_caches
    File.read("#{tmp}/root/cssbase/lib.css").should == "style1 { background: #000 }style2 { background: #fff }"
    File.read("#{tmp}/root/jsbase/lib.js").should == "function f2(){alert('2');}function f1(){alert('1');}"
  end

  def write_file(path, content)
    FileUtils.mkdir_p File.dirname(path)
    open(path, 'w'){|f| f.print content}
  end
end
