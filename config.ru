require 'json'
require 'httparty'
require 'debugger'

def generate_response(verb, callback_url)
end

def generate_request(env)
  req = Rack::Request.new(env)
  verb = req.params["verb"]
  verb = "get" if verb.nil?
  verb.downcase!

  response = {
    verb: verb
  }

  callback_url = req.params["callback_url"]
  if callback_url.nil?
    response[:status] = "error"
    response[:message] = "You did not specify a callback_url! in your url. Do so by doing something like this: 'GET http://callbackechoer.com?callback_url=example.com&verb=post'"
  else callback_url[0..3] != "http"
    response[:status] = "error"
    response[:message] = "your callback url must begin with 'http' or 'https'
  else
    response[:callback_url] = callback_url
  end

  if %w{get post}.include?(verb)
    begin
      response_from_callback_url = eval("HTTParty.#{verb}(callback_url)")
      response[:status] = "success"
      response[:message] = response_from_callback_url
    rescue Exception => e
      response[:status] = "error"
      response[:message] = e.to_s
      puts e.backtrace.join("\n")
    end
  else
    response[:status] = "error"
    response[:message] = "The verb #{verb} is not supported, only 'get' and 'post' are supported."
  end

  return StringIO.new(response.to_json)
end


run lambda { |env| 
  [200, {'Content-Type'=>'text/plain'}, generate_request(env)]
}
