require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'

configure do
  enable :sessions
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Hello stranger'
  end
end

before '/secure/*' do
  unless session[:identity]
    session[:previous_url] = request.path
    @error = 'Sorry, you need to be logged in to visit ' + request.path
    halt erb(:login_form)
  end
end

get '/' do
  erb 'Can you handle a <a href="/secure/place">secret</a>?'
end

get '/login/form' do
  erb :login_form
end

get '/visit' do
  erb :visit
end

post '/visit' do
  @user_name = params[:user_name]
  @phone = params[:phone]
  @date_time = params[:date_time]
  @barber = params[:barber]
  @color = params[:colorpicker]

  @message = "Dear #{@user_name}, our Barber #{@barber} we'll be waiting for you at #{@date_time}"

  f = File.open('users.txt', 'a')
  f.write "#{@user_name}, #{@phone}, #{@barber}, #{@date_time}, #{@color},\n"
  f.close

  erb :visit
end

post '/login/attempt' do
  session[:identity] = params['username']
  @password = params['password']
  if @password == 'sec'
    where_user_came_from = session[:previous_url] || '/'
    redirect to where_user_came_from
  else
    @error = "Wrong password"
    erb :login_form
  end
end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Logged out</div>"
end

get '/secure/place' do
  @cust_arr = []
  @customer_file = File.read('users.txt').strip.split(",")
  @cust_arr << @customer_file.each_slice(5).to_a
  
  erb :users
end
