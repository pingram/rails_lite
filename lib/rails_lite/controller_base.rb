require 'erb'
require 'active_support/inflector'
require 'json'
require_relative 'params'
require_relative 'session'


class ControllerBase
  attr_reader :params, :req, :res

  # setup the controller
  def initialize(req, res, route_params = {})
    @req = req
    @res = res
    @already_built_response = false
  end

  # populate the response with content
  # set the responses content type to the given type
  # later raise an error if the developer tries to double render
  def render_content(content, type)
    ensure_no_double_render
    session.store_session(res)

    @res.content_type = type
    @res.body = content
    @already_built_response = true
  end

  # helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # set the response status code and header
  def redirect_to(url)
    ensure_no_double_render
    session.store_session(res)

    @res.status = 302
    @res.header["location"] = url
    @already_built_response = true
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    template_path = root_path +
                    "/" +
                    "views/" +
                    self.class.to_s.underscore +
                    "/" +
                    template_name.to_s +
                    ".html.erb"

    template = ERB.new(File.read(template_path))
    template_result = template.result(binding)
    render_content(template_result, "text/html")
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(req)
    # @session.store_session(res)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name)
    render(name) unless already_built_response?
  end

  # private

  def ensure_no_double_render
    raise "double render!" if already_built_response?
  end

  def root_path
    File.expand_path(Dir.pwd)
  end
end


# class UsersController < ControllerBase
#   def index
#   end
# end
# UsersController.new.render(:index)

# req = WEBrick::HTTPRequest.new(:Logger => nil)
# res = WEBrick::HTTPResponse.new(:HTTPVersion => '1.0')
# cookie = WEBrick::Cookie.new('_rails_lite_app', { :xyz=> 'abc' }.to_json)