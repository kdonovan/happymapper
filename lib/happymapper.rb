dir = File.dirname(__FILE__)
$:.unshift(dir) unless $:.include?(dir) || $:.include?(File.expand_path(dir))

require 'date'
require 'time'
require 'rubygems'
gem 'libxml-ruby', '= 0.9.8'
require 'xml'

class Boolean; end

module HappyMapper

  DEFAULT_NS = "happymapper"

  def self.included(base)
    base.instance_variable_set("@attributes", {})
    base.instance_variable_set("@elements", {})
    base.send :attr_accessor,  :raw_xml
    base.extend ClassMethods
  end
  
  def to_xml
    doc = LibXML::XML::Document.new
    doc.root = to_xml_node
    doc.to_s
  end
  
  def to_xml_node(root_node = nil)
    node = XML::Node.new(self.class.tag_name)
    root_node ||= node
    # add namespace to node and to root_element if not already set
    if self.class.namespace_url
      if root_node
        namespace_object = root_node.namespaces.find_by_href(self.class.namespace_url)
        namespace_object ||= XML::Namespace.new root_node, self.class.namespace, self.class.namespace_url
        node.namespaces.namespace = namespace_object
      end
    end
    # serialize elements
    self.class.elements.each do |e|
      if e.options[:single] == false
        self.send("#{e.method_name}").each do |array_element|
          node << e.to_xml_node(array_element,root_node)
        end
      else
        element_value = self.send("#{e.method_name}")
        node << e.to_xml_node(element_value,root_node) unless element_value.nil?
      end
    end
    # serialize attributes
    self.class.attributes.each do |a|
      attribute_value = self.send("#{a.method_name}")
      node.attributes[a.tag] = attribute_value.to_s unless attribute_value.nil? 
    end
    node
  end

  module ClassMethods
    # Control storing of raw XML data (off by default, but can be useful in certain situations)
    @store_raw_xml = false

    # Tell HappyMapper to store the raw XML in the appropriately-named raw_xml instance variable when parsing
    def archive_raw_xml
      @store_raw_xml = true
    end
    
    def store_raw_xml?
      @store_raw_xml
    end
    
    def attribute(name, type, options={})
      attribute = Attribute.new(name, type, options)
      @attributes[to_s] ||= []
      @attributes[to_s] << attribute
      attr_accessor attribute.method_name.intern
    end

    def attributes
      @attributes[to_s] || []
    end

    def element(name, type, options={})
      options = {:namespace => @namespace}.merge(options)
      element = Element.new(name, type, options)
      @elements[to_s] ||= []
      @elements[to_s] << element
      attr_accessor element.method_name.intern
      
      # set the default value of a collection instance variable to [] instead of nil
      if options[:single] == false
        module_eval <<-eof
          def #{element.method_name}
            @#{element.method_name} ||= []
          end
        eof
      end
    end

    def elements
      @elements[to_s] || []
    end

    def has_one(name, type, options={})
      element name, type, {:single => true}.merge(options)
    end

    def has_many(name, type, options={})
      element name, type, {:single => false}.merge(options)
    end

    # Specify a namespace if a node and all its children are all namespaced
    # elements. This is simpler than passing the :namespace option to each
    # defined element.
    #
    # namespace can either be a string for the prefix or a hash with 'prefix' => 'url'
    def namespace(namespace = nil)
      if namespace
        if namespace.is_a? Hash
          namespace.each_pair do |k,v|
            @namespace = k.to_s
            @namespace_url = v
          end
        else  
          @namespace = namespace 
        end
      end
      @namespace
    end
    
    def namespace_url(url = nil)
      @namespace_url = url if url
      @namespace_url
    end

    def tag(new_tag_name)
      @tag_name = new_tag_name.to_s
    end

    def tag_name
      @tag_name ||= to_s.split('::')[-1].downcase
    end

    def parse(xml, options = {})
      # locally scoped copy of namespace for this parse run
      namespace = @namespace

      if xml.is_a?(XML::Node)
        node = xml
      else
        if xml.is_a?(XML::Document)
          node = xml.root
        else
          node = XML::Parser.string(xml).parse.root
        end

        root = node.name == tag_name
      end

      # This is the entry point into the parsing pipeline, so the default
      # namespace prefix registered here will propagate down
      namespaces = node.namespaces
      if @namespace_url && namespaces.default.href != @namespace_url
        namespace = namespaces.find_by_href(@namespace_url).prefix
      elsif namespaces && namespaces.default
        # don't assign the default_prefix if it has already been assigned
        namespaces.default_prefix = DEFAULT_NS unless namespaces.find_by_prefix(DEFAULT_NS)
        namespace ||= DEFAULT_NS
      end

      xpath = root ? '/' : (options[:deep]) ? './/' : './'
      xpath += "#{namespace}:" if namespace
      xpath += tag_name
      # puts "parse: #{xpath}"

      nodes = node.find(xpath)
      collection = nodes.collect do |n|
        obj = new
        obj.raw_xml = n.to_s if obj.class.store_raw_xml?

        attributes.each do |attr|
          obj.send("#{attr.method_name}=",
                    attr.from_xml_node(n, namespace))
        end

        elements.each do |elem|
          obj.send("#{elem.method_name}=",
                    elem.from_xml_node(n, namespace))
        end

        obj
      end

      # per http://libxml.rubyforge.org/rdoc/classes/LibXML/XML/Document.html#M000354
      nodes = nil

      if options[:single] || root
        collection.first
      else
        collection
      end
    end
    
    # Load for custom Marshaling
    def _load(xml_str)
      self.parse(xml_str)
    end
  end
  
  # Define _load and _dump to allow Marshaling of HappyMapper objects.  Note that this isn't as efficient as a 
  # binary data store could be, but such is the nature of XML.
  def _dump(depth)
    @raw_xml || self.to_xml
  end
  
end

require 'happymapper/item'
require 'happymapper/attribute'
require 'happymapper/element'
