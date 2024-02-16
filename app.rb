require 'slim' 
require 'sinatra' 
require 'sinatra/reloader'
require_relative './model/model.rb'
require_relative './controller/auth.rb'


get ('/') do 
    # check_auth(id)
    slim(:'users/index')
end

get ('/users/new') do
    slim(:'users/new')
end

post('/login') do 
    name = params[:name]
    password = params[:password]
    usr = login_user(name, password)
    if usr == nil
        err = "Inloggning misslyckad"
    else
        session[:userinfo] = usr
    end
end

post('/users/new') do
    name = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    phone = params[:phonenumber]

    if password = password_confirm
     register_user(password, name, phone)
     redirect('/')
    else
     #felhantering (tempoärär)
     "The passwords were not the same"
    end
end
