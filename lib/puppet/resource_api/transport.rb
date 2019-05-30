module Puppet::ResourceApi; end # rubocop:disable Style/Documentation

# Remote target transport API
module Puppet::ResourceApi::Transport
  def register(schema)
    definition = Puppet::ResourceApi::TransportSchemaDef.new(schema)

    unless transports[definition.name].nil?
      raise Puppet::DevError, 'Transport `%{name}` is already registered for `%{environment}`' % {
        name: definition.name,
        environment: current_environment,
      }
    end

    transports[schema[:name]] = definition
  end
  module_function :register # rubocop:disable Style/AccessModifierDeclarations

  # retrieve a Hash of transport schemas, keyed by their name.
  def list
    Marshal.load(Marshal.dump(transports))
  end
  module_function :list # rubocop:disable Style/AccessModifierDeclarations

  def connect(name, connection_info)
    validate(name, connection_info)
    require "puppet/transport/#{name}"
    class_name = name.split('_').map { |e| e.capitalize }.join
    Puppet::Transport.const_get(class_name).new(get_context(name), wrap_sensitive(name, connection_info))
  end
  module_function :connect # rubocop:disable Style/AccessModifierDeclarations

  def inject_device(name, transport)
    transport_wrapper = Puppet::ResourceApi::Transport::Wrapper.new(name, transport)

    if Puppet::Util::NetworkDevice.respond_to?(:set_device)
      Puppet::Util::NetworkDevice.set_device(name, transport_wrapper)
    else
      Puppet::Util::NetworkDevice.instance_variable_set(:@current, transport_wrapper)
    end
  end
  module_function :inject_device # rubocop:disable Style/AccessModifierDeclarations

  def self.validate(name, connection_info)
    require "puppet/transport/schema/#{name}" unless transports.key? name
    transport_schema = transports[name]
    if transport_schema.nil?
      raise Puppet::DevError, 'Transport for `%{target}` not registered with `%{environment}`' % {
        target: name,
        environment: current_environment,
      }
    end
    message_prefix = 'The connection info provided does not match the Transport Schema'
    transport_schema.check_schema(connection_info, message_prefix)
    transport_schema.validate(connection_info)
  end
  private_class_method :validate

  def self.get_context(name)
    require 'puppet/resource_api/puppet_context'
    Puppet::ResourceApi::PuppetContext.new(transports[name])
  end
  private_class_method :get_context

  def self.wrap_sensitive(name, connection_info)
    transport_schema = transports[name]
    if transport_schema
      transport_schema.definition[:connection_info].each do |attr_name, options|
        if options.key?(:sensitive) && (options[:sensitive] == true) && connection_info.key?(attr_name)
          connection_info[attr_name] = Puppet::Pops::Types::PSensitiveType::Sensitive.new(connection_info[attr_name])
        end
      end
    end
    connection_info
  end
  private_class_method :wrap_sensitive

  def self.transports
    @transports ||= {}
    @transports[current_environment] ||= {}
  end
  private_class_method :transports

  def self.current_environment
    if Puppet.respond_to? :lookup
      env = Puppet.lookup(:current_environment)
      env.nil? ? :transports_default : env.name
    else
      :transports_default
    end
  end
  private_class_method :current_environment
end
