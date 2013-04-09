# encoding: UTF-8

require 'json'
require 'httparty'

def generate_request(env)
  render_response = Proc.new do
    return StringIO.new(@response.to_json)
  end

  req = Rack::Request.new(env)
  verb = req.params["verb"]
  verb = "get" if verb.nil?
  verb.downcase!

  @response = {
    verb: verb
  }

  callback_url = req.params["callback_url"]

  if callback_url.nil?
    @response[:status] = "error"
    @response[:message] = "You did not specify a callback_url! in your url. Do so by doing something like this: 'GET http://callbackmemaybe.com?callback_url=yourwebsite.com&verb=post'"
    render_response.call
  
  elsif callback_url[0..3] != "http"
    @response[:status] = "error"
    @response[:message] = "your callback url must begin with 'http' or 'https'"
    render_response.call
  
  else
    @response[:callback_url] = callback_url

  end

  if %w{get post head}.include?(verb)
    begin
      response_from_callback_url = eval("HTTParty.#{verb}(callback_url)")
      @response[:status] = "success"
      @response[:message] = response_from_callback_url.response.body.force_encoding("UTF-8")

    rescue Exception => e
      @response[:status] = "error"
      @response[:message] = e.class
    end
  else
    @response[:status] = "error"
    @response[:message] = "The verb #{verb} is not supported, only 'get' and 'post' are supported."
  end

  render_response.call

end

run lambda { |env| 
  [200, {'Content-Type'=>'application/json'}, generate_request(env)]
}
