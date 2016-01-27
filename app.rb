require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

configure do
  enable :sessions
  db = get_db
  db.execute 'CREATE TABLE IF NOT EXISTS "Users" ("Id" INTEGER PRIMARY KEY AUTOINCREMENT, "Name" VARCHAR, "Phone" VARCHAR, "DateStamp" VARCHAR, "Barber" VARCHAR, "Color" VARCHAR);'
  db.execute 'CREATE TABLE IF NOT EXISTS "Contacts" ("Id" INTEGER PRIMARY KEY AUTOINCREMENT, "Email" VARCHAR, "Message" VARCHAR);'
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
  @username = params[:username_c]
  @phone = params[:phone_c]
  @datetime = params[:datetime_c]
  @barber = params[:barber]
  @color = params[:colorpicker]

  fval = { :username_c => 'Введите имя',
            :phone_c => 'Введите телефон',
            :datetime_c => 'Введите дату и время',
            :barber => 'Выберите парикмахера',
            :colorpicker => 'Выберите цвет'}

  @error = fval.select {|key,_| params[key] == ""}.values.join(", ")

  if @error == ""
    @message = "Dear #{@username}, our Barber #{@barber} we'll be waiting for you at #{@datetime}"
    f = File.open('users.txt', 'a')
    f.write "#{@username}, #{@phone}, #{@barber}, #{@datetime}, #{@color},\n"
    f.close
  end

  db = get_db
  db.execute 'insert into Users (Name, Phone, DateStamp, Barber, Color) values (?, ?, ?, ?, ?)', [@username, @phone, @datetime, @barber, @color]

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

def get_db
  return SQLite3::Database.new 'barbershop.db'
end