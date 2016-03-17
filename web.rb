require 'sinatra'
require 'dotenv'

Dotenv.load

get '/?' do
  "Hello, World!"
end

get '/env/?' do
  out = ""
  ENV.each do |k,v|
    out += k + ": " + v + "<br/>"
  end
  out
end
