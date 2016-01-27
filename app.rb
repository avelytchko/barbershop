require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'
require 'tilt/erb'

def get_db
  db = SQLite3::Database.new 'barbershop.db'
  db.results_as_hash = true
  return db
end

configure do
  enable :sessions
  db = get_db
  db.execute 'CREATE TABLE IF NOT EXISTS "barbers" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "name" VARCHAR UNIQUE);'
  db.execute 'INSERT OR IGNORE INTO barbers ("name") values ("Walter White");'
  db.execute 'INSERT OR IGNORE INTO "barbers" ("name") values ("Jessie Pinkman");'
  db.execute 'INSERT OR IGNORE INTO "barbers" ("name") values ("Hank Schrader");'
  db.execute 'INSERT OR IGNORE INTO "barbers" ("name") values ("Gus Fring");'
  db.execute 'INSERT OR IGNORE INTO "barbers" ("name") values ("Saul Goodman");'
  db.execute 'INSERT OR IGNORE INTO "barbers" ("name") values ("Skyler White");'
  db.execute 'CREATE TABLE IF NOT EXISTS "users" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "name" VARCHAR, "phone" VARCHAR, "datestamp" VARCHAR, "barber" VARCHAR, "color" VARCHAR);'
  db.execute 'CREATE TABLE IF NOT EXISTS "contacts" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "email" VARCHAR, "message" VARCHAR);'
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

get '/showusers' do
  erb :showusers
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
    f.write "#{@username}, #{@datetime}, #{@phone}, #{@barber}, #{@color},\n"
    f.close
    db = get_db
    db.execute 'insert into users (name, phone, datestamp, barber, color) values (?, ?, ?, ?, ?)', [@username, @phone, @datetime, @barber, @color]
  end

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