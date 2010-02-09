require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../lib/asset_library'

module TemporaryDirectory
  TMP = File.expand_path(File.dirname(__FILE__) + 'tmp')

  def self.included(base)
    base.before do
      remove_tmp
      make_tmp
      enter_tmp
    end

    base.after do
      leave_tmp
      remove_tmp
    end
  end

  def make_tmp
    FileUtils.mkdir_p tmp
  end

  def remove_tmp
    FileUtils.rm_rf tmp
  end

  def enter_tmp
    @original_pwd = Dir.pwd
    Dir.chdir tmp
  end

  def leave_tmp
    Dir.chdir @original_pwd
  end

  def tmp
    TMP
  end
end
