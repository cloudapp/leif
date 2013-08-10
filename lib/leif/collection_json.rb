require 'delegate'
require 'forwardable'

module Leif
  module CollectionJson
    class Collection
      extend Forwardable
      def_delegators :@data, :fetch, :has_key?

      def initialize(body)
        @data = body.fetch('collection')
      end

      def link_href(relation)
        links.find {|link| link.fetch('rel') == relation }.fetch('href')
      end

      def link_relations
        links.map {|link| link.fetch('rel') }
      end

      def links
        return [] unless has_key?('links')
        fetch('links')
      end

      def items
        return [] unless has_key?('items')
        fetch('items')
      end

      def template(href = fetch('href'), method = :post)
        Template.new(fetch('template'), href, method)
      end

      def item_template(item)
        template = template(item.fetch('href'), :put)
        item.fetch('data').inject(template) {|template, datum|
          template.fill_field datum.fetch('name'), datum.fetch('value')
        }
      end

      class Template < SimpleDelegator
        attr_accessor :href, :method

        def initialize(template, href, method)
          @href   = href
          @method = method
          super template
        end

        def convert_to_json
          fetch('data').each_with_object({}) do |datum, json|
            json[datum['name']] = datum['value']
          end
        end

        def fill_field(name, value)
          new_data = fetch('data').map {|datum|
            datum = datum.clone
            datum['value'] = value if datum['name'] == name
            datum
          }
          new_template = {'data' => new_data }
          Template.new(new_template, href, method)
        end
      end
    end
  end
end