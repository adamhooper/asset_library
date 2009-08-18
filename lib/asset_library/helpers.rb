class AssetLibrary
  module Helpers
    def asset_library_javascript_tags(module_key, format = nil)
      m = AssetLibrary.asset_module(module_key)
      if AssetLibrary.cache
        @@asset_library_javascript_tags_cache ||= {}
        @@asset_library_javascript_tags_cache[module_key] ||= script_tag(m.cache_asset.relative_url)
      else
        m.assets(format).collect{|a| script_tag(a.relative_url)}.join("\n")
      end
    end

    def asset_library_stylesheet_tags(module_key, format = nil)
      m = AssetLibrary.asset_module(module_key)
      if AssetLibrary.cache
        @@asset_library_stylesheet_tags_cache ||= {}
        @@asset_library_stylesheet_tags_cache[[module_key, format]] ||= style_tag(m.cache_asset(format).relative_url)
      else
        import_styles_tag(m.assets(format).collect{|a| a.relative_url})
      end
    end

    private

    def script_tag(url)
      "<script type=\"text/javascript\" src=\"#{url}\"></script>"
    end

    def style_tag(url)
      "<link rel=\"stylesheet\" type=\"text/css\" href=\"#{url}\" />"
    end

    def import_styles_tag(urls)
      a = []
      urls.each_slice(30) do |subset|
        a << import_style_tag(subset)
      end
      a.join("\n")
    end

    def import_style_tag(urls)
      imports = urls.collect{ |u| "@import \"#{u}\";" }
      "<style type=\"text/css\">\n#{imports.join("\n")}\n</style>"
    end
  end
end
