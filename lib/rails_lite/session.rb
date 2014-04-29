require 'json'
require 'webrick'

class Session
  # find the cookie for this app
  # deserialize the cookie into a hash
  def initialize(req)
    @cookies = {}

    unless req.cookies.nil?
      req.cookies.each do |cookie|
        if cookie.name == "_rails_lite_app"
          cookie_json = JSON.parse(cookie.value)
          @cookies[cookie_json.keys.first] = cookie_json.values.last
        end
      end
    end
  end

  def [](key)
    @cookies[key]
  end

  def []=(key, val)
    @cookies[key] = val
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_session(res)
    my_cookie = WEBrick::Cookie.new('_rails_lite_app', @cookies.to_json)
    res.cookies << my_cookie
  end
end

# req = WEBrick::HTTPRequest.new(:Logger => nil)
# res = WEBrick::HTTPResponse.new(:HTTPVersion => '1.0')
# cook = WEBrick::Cookie.new('_rails_lite_app', { :xyz=> 'abc' }.to_json)
# req.cookies << cook

# session = Session.new(req)
# p session