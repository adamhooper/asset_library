require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../lib/asset_library'

def attributes_to_hash(string, without = [])
  hash_from_tag_attributes = {}
  
  string.scan(/\s([^\s=]+="[^"]*)"/).each do |attr| 
    a = attr[0].split("=\"")
    hash_from_tag_attributes.merge!( a[0].to_sym => a[1] ) 
  end
  
  without.each{|k| hash_from_tag_attributes.delete k} 
  
  hash_from_tag_attributes
end
