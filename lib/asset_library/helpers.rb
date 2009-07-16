class AssetLibrary
  module Helpers
    def asset_library_javascript_tags(module_key)
      m = AssetLibrary.asset_module(module_key)
      if AssetLibrary.cache
        script_tag(m.cache_asset.relative_url)
      else
        m.assets.collect{|a| script_tag(a.relative_url)}.join("\n")
      end
    end

    def asset_library_stylesheet_tags(module_key, extra_suffix = nil)
      m = AssetLibrary.asset_module(module_key)
      if AssetLibrary.cache
        style_tag(m.cache_asset(extra_suffix).relative_url)
      else
        import_styles_tag(m.assets(extra_suffix).collect{|a| a.relative_url})
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
      urls.enum_slice(30).collect{ |subset| import_style_tag(subset) }.join("\n")
    end

    def import_style_tag(urls)
      imports = urls.collect{ |u| "@import \"#{u}\";" }
      "<style type=\"text/css\">\n#{imports.join("\n")}\n</style>"
    end
  end
end
