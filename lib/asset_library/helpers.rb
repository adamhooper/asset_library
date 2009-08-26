class AssetLibrary
  module Helpers
    def asset_library_javascript_tags(module_key, format = nil)
      m = AssetLibrary.asset_module(module_key)
      if AssetLibrary.cache
        AssetLibrary.cache_vars[:javascript_tags] ||= {}
        AssetLibrary.cache_vars[:javascript_tags][module_key] ||= asset_library_priv.script_tag(m.cache_asset)
      else
        m.assets(format).collect{|a| asset_library_priv.script_tag(a)}.join("\n")
      end
    end

    def asset_library_stylesheet_tags(module_key, format = nil)
      m = AssetLibrary.asset_module(module_key)
      if AssetLibrary.cache
        AssetLibrary.cache_vars[:stylesheet_tags] ||= {}
        AssetLibrary.cache_vars[:stylesheet_tags][[module_key, format]] ||= asset_library_priv.style_tag(m.cache_asset(format))
      else
        asset_library_priv.import_styles_tag(m.assets(format))
      end
    end

    private

    def asset_library_priv
      @asset_library_priv ||= Priv.new(self)
    end

    class Priv
      # Don't pollute helper's class's namespace with all our methods; put
      # them here instead

      attr_accessor :helper

      def initialize(helper)
        @helper = helper
      end

      def url(asset)
        absolute_url(asset.relative_url)
      end

      def absolute_url(relative_url)
        host = helper.__send__(:compute_asset_host, relative_url) if helper.respond_to?(:compute_asset_host, true)

        host = nil if host == '' # Rails sets '' by default

        if host && !(host =~ %r{^[-a-z]+://})
          controller = helper.instance_variable_get(:@controller)
          request = controller && controller.respond_to?(:request) && controller.request
          host = request && "#{request.protocol}#{host}"
        end

        if host
          "#{host}#{relative_url}"
        else
          relative_url
        end
      end

      def script_tag(asset)
        "<script type=\"text/javascript\" src=\"#{url(asset)}\"></script>"
      end

      def style_tag(asset)
        "<link rel=\"stylesheet\" type=\"text/css\" href=\"#{url(asset)}\" />"
      end

      def import_styles_tag(assets)
        a = []
        assets.each_slice(30) do |subset|
          a << import_style_tag(subset)
        end
        a.join("\n")
      end

      def import_style_tag(assets)
        imports = assets.collect{ |a| "@import \"#{url(a)}\";" }
        "<style type=\"text/css\">\n#{imports.join("\n")}\n</style>"
      end
    end
  end
end
