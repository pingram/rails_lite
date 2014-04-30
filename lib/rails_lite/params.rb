require 'uri'
require 'webrick'
require 'active_support/core_ext'
# require_relative 'controller_base'

class Params
  # use your initialize to merge params from
  # 1. query string
  # 2. post body
  # 3. route params
  def initialize(req, route_params = {})
    @params = route_params
    @permitted = []
    parse_www_encoded_form(req.query_string)
    parse_post_body(req)
    parse_route_params(route_params)
  end

  def [](key)
    @params[key]
  end

  def permit(*keys)
    @permitted += keys
  end

  def require(key)
    raise AttributeNotFoundError.new unless @params.include?(key)
  end

  def permitted?(key)
    return true if @permitted.include?(key)
    false
  end

  def to_s
  end

  class AttributeNotFoundError < ArgumentError; end;

  private

  def parse_post_body(req)
    parse_www_encoded_form(req.body)
  end

  def parse_route_params(route_params)
    route_params.each do |key, value|
      @params[key] = value
    end
  end

  # this should return deeply nested hash
  # argument format
  # user[address][street]=main&user[address][zip]=89436
  # should return
  # { "user" => { "address" => { "street" => "main", "zip" => "89436" } } }
  def parse_www_encoded_form(www_encoded_form)
    return if www_encoded_form.nil?
    query_param_array = URI::decode_www_form(www_encoded_form)

    query_param_array.each do |single_qp|
      keys = parse_key(single_qp.first)
      value = single_qp.last
      new_hash = build_params_hash(keys, value)
      @params.deep_merge!(new_hash)
    end

    @params
  end

  def build_params_hash(keys, value)
    if keys.length < 2
      h = Hash.new
      h[keys.last] = value
      return h
    end
    h2 = Hash.new
    h2[keys.first] = build_params_hash(keys[1..-1], value)
    h2
  end

  # this should return an array
  # user[address][street] should return ['user', 'address', 'street']
  def parse_key(key)
    array = key.split(/\]\[|\[|\]/)
  end
end

# class UsersController < ControllerBase
#       def index
#       end
#     end
# req = WEBrick::HTTPRequest.new(:Logger => nil)
# res = WEBrick::HTTPResponse.new(:HTTPVersion => '1.0')
# users_controller = UsersController.new(req, res)
# req.query_string = "key=val&face=mace"
# params = Params.new(req)
# keys = Params.new.parse_key('user[address][street]')
# p keys
# p Params.new.build_params_hash(keys ,'main')
# p Params.new.parse_www_encoded_form('user[address][street]=main&user[address][zip]=89436)')
