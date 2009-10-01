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

    def asset_library_stylesheet_tags(module_key, *args)
      html_options = args.last.is_a?(Hash) ? args.pop : {}
      format = args[0]
      
      m = AssetLibrary.asset_module(module_key)
      if AssetLibrary.cache
        AssetLibrary.cache_vars[:stylesheet_tags] ||= {}
        AssetLibrary.cache_vars[:stylesheet_tags][[module_key, format]] ||= asset_library_priv.style_tag(m.cache_asset(format), html_options)
      else
        asset_library_priv.import_styles_tag(m.assets(format), html_options)
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
        content_tag(:script, "", {:type => "text/javascript", :src => url(asset)})
      end

      def style_tag(asset, html_options = {})
        "<link rel=\"stylesheet\" type=\"text/css\" href=\"#{url(asset)}\" #{attributes_from_hash(html_options)}/>"
      end

      def import_styles_tag(assets, html_options = {})
        a = []
        assets.each_slice(30) do |subset|
          a << import_style_tag(subset, html_options)
        end
        a.join("\n")
      end

      def import_style_tag(assets, html_options = {})
        imports = assets.collect{ |a| "@import \"#{url(a)}\";" }
        content_tag(:style, "\n#{imports.join("\n")}\n", html_options.merge(:type => "text/css"))
      end
      
      def content_tag(name, content, options = {})        
        "<#{name} #{attributes_from_hash(options)}>#{content}</#{name}>"
      end
      
      def attributes_from_hash(options = {})
        options.to_a.collect{|k, v| "#{k}=\"#{v}\""}.join(" ")
      end
      
    end
  end
end
