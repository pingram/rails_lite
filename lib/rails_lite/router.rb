# require 'ndebug'

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
    all_route_params = req.path.gsub(@pattern, '')
    route_path = req.path.gsub(all_route_params, '')
    route_params = {}
    # XXX come back to this

    # p route_params
    # need to call constantize to get the class name
    # controller_class_str = (route_path.gsub('/','') + "_controller").classify
    my_controller = @controller_class.new(req, res, route_params)
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
  end

  # make each of these methods that
  # when called add route
  [:get, :post, :put, :delete].each do |http_method|
  end

  # should return the route that matches this request
  def match(req)
    @routes.select do |route|
      route.matches?(req)
    end.first
  end

  # either throw 404 or call run on a matched route
  def run(req, res)
    res.status = 404 if self.match(req).nil?
  end
end

# p index_route = Route.new(Regexp.new("^/users$"), :get, "x", :x)
