require 'sinatra'
require 'dotenv'

Dotenv.load

get '/?' do
  erb :index
end
