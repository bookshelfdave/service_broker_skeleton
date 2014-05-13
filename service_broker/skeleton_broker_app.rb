require 'sinatra'
require 'json'
require 'yaml'


class DummyServiceInstance
  attr_accessor :id
  attr_accessor :bindings

  def initialize(id)
      @id = id
      @bindings = {}
  end
end

class SkeletonBrokerApp < Sinatra::Base
  #configure the Sinatra app

  def initialize
    super
    @@instances = {}
  end

  use Rack::Auth::Basic do |username, password|
    credentials = self.app_settings.fetch("basic_auth")
    username == credentials.fetch("username") and password == credentials.fetch("password")
  end

  # Service Broker API implementation

  # CATALOG
  get "/v2/catalog" do
    content_type :json
    self.class.app_settings.fetch("catalog").to_json
  end

  # PROVISION
  put "/v2/service_instances/:id" do |id|
    content_type :json
    begin

      if @@instances.has_key?(id) then
          status 409
          {"description" => "ID #{id} already exists"}.to_json
      else
        status 201
        @@instances[id] = DummyServiceInstance.new(id)
        # description isn't appropriate here, but I had nothing to return
        {"description" => "Skeleton service #{id} provisioned"}.to_json
      end
    rescue Exception => e
      status 502
      {"description" => e.message}.to_json
    end
  end

  # UNPROVISION
  delete '/v2/service_instances/:instance_id' do |instance_id|
    content_type :json

    begin
      if not @@instances.has_key?(instance_id) then
        status 410
        {"description" => "#{instance_id} does not exist"}.to_json
      else
        @@instances.delete(instance_id)
        status 200
        {"description" => "#{instance_id} removed"}.to_json
      end
      {}.to_json
    rescue Exception => e
      status 502
      {"description" => e.message}.to_json
    end
  end

  # BIND
  put '/v2/service_instances/:instance_id/service_bindings/:id' do |instance_id, binding_id|
    content_type :json

    begin
      if not @@instances.has_key?(instance_id) then
        status 404
        {"description" => "Instance #{instance_id} not found"}.to_json
      else
        instance =  @@instances[instance_id]
        if instance.bindings.has_key?(binding_id) then
          status 409
          {"description" => "The binding #{binding_id} already exists"}.to_json
        else
          instance.bindings[binding_id] = true
          status 201
          {"description" => "Service #{instance_id} bound with #{binding_id}"}.to_json
        end
      end
    rescue Exception => e
      status 502
      {"description" => e.message}.to_json
    end
  end

  # UNBIND
  delete '/v2/service_instances/:instance_id/service_bindings/:id' do |instance_id, binding_id|
    content_type :json

    begin
      if not @@instances.has_key?(instance_id) then
        status 410
        {}.to_json
      else
        instance = @@instances[instance_id]
        if not instance.bindings.has_key?(binding_id) then
          status 410
          {}.to_json
        else
          instance.bindings.delete(binding_id)
          status 200
          {"description" => "Binding removed"}.to_json
        end
      end
    rescue Exception => e
      status 502
      {"description" => e.message}.to_json
    end
  end


  private

  def self.app_settings
    settings_filename = defined?(SETTINGS_FILENAME) ? SETTINGS_FILENAME : 'config/settings.yml'
    @app_settings ||= YAML.load_file(settings_filename)
  end

end
