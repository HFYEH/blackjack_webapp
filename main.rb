require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

get '/new_game' do 
  erb :new_game
end

post '/new_game' do 
  #binding.pry
  session[:player_name] = params[:player_name]
  redirect '/bet'
end

post '/bet' do 
  session[:bet] = params[:bet]
  redirect '/game'
end

get '/bet' do 
  session[:money] = 500 if session[:money].nil?
  erb :bet
end

get '/game' do 

  erb :game 
end