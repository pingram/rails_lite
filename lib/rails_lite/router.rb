# require 'debugger'
require 'webrick'

class Route
  attr_reader :pattern, :http_method, :controller_class, :action_name

  def initialize(pattern, http_method, controller_class, action_name)
    if pattern.is_a?(Regexp)
      @pattern = pattern
    else
      @pattern = Regexp.new(pattern.to_s)
    end
    @http_method = http_method
    @controller_class = controller_class
    @action_name = action_name
  end

  # checks if pattern matches path and method matches request method
  def matches?(req)
    req_method = req.request_method.downcase.to_sym
    req_path = req.path

    if !@pattern.match(req_path).nil? && @http_method == req_method
      true
    else
      false
    end
  end

  # use pattern to pull out route params (save for later?)
  # instantiate controller and call controller action
  def run(req, res)
    path_params = {}
    mdata = @pattern.match(req.path)

    mdata.names.each do |mdatum|
      path_params[mdatum] = mdata[mdatum]
    end

    my_controller = @controller_class.new(req, res, path_params)
    my_controller.invoke_action(@action_name)
  end
end

class Router
  attr_reader :routes

  def initialize
    @routes = []
  end

  # simply adds a new route to the list of routes
  def add_route(pattern, method, controller_class, action_name)
    @routes << Route.new(pattern, method, controller_class, action_name)
  end

  # evaluate the proc in the context of the instance
  # for syntactic sugar :)
  def draw(&proc)
    self.instance_eval(&proc)
    self
  end

  # make each of these methods that
  # when called add route
  [:get, :post, :put, :delete].each do |http_method|
    define_method(http_method) do |pattern, controller_class, action_name|
      @routes << Route.new(pattern, http_method, controller_class, action_name)
    end
  end

  # should return the route that matches this request
  def match(req)
    @routes.select do |route|
      route.matches?(req)
    end.first
  end

  # either throw 404 or call run on a matched route
  def run(req, res)
    matching_route = self.match(req)
    if matching_route.nil?
      res.status = 404
      return
    end
    matching_route.run(req, res)
  end
end

# index_route = Route.new(Regexp.new("^/statuses/(?<id>\\d+)$"), :get, "x", :x)
# req = WEBrick::HTTPRequest.new(:Logger => nil, :path => '/statuses/1')
# res = WEBrick::HTTPResponse.new(:HTTPVersion => '1.0')
# p req.path
# index_route.run(req, res)
# class StatusesController; end

# router = Router.new
# router.draw do
#   post Regexp.new("^/statuses$"), StatusesController, :create
#   get Regexp.new("^/statuses/new$"), StatusesController, :new
# end

# p router