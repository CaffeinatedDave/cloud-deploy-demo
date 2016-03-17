require 'sinatra'
require 'dotenv'

Dotenv.load

get '/?' do
  erb :index
end

get '/env/?' do
  out = ""
  ENV.sort.each do |k,v|
    out += k + ": " + v + "<br/>"
  end
  out
end
