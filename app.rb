require "slim"
require "sinatra"
require "sinatra/reloader"
require_relative "./model/model.rb"
require_relative "./controller/auth.rb"

enable :sessions

include Model

get ("/") do
  userinfo = session[:userinfo]

  slim(:index, locals: {user: userinfo})
end

get ("/ship/:id") do
  session[:shipid] = params[:id].to_i
  session[:shipname] = get_ship(params[:id].to_i) 
  redirect("/")
end

get ("/users/new") do
  slim(:'users/new')
end

get ("/login") do
 
  slim(:'users/index', locals: { email: session[:email] })
end

get ("/logout") do
  session.clear
  redirect("/")
end

# Rutt för inloggning
# @see #login_user
post("/users/login") do
  email = params[:email]
  password = params[:password]
  usr = login_user(email, password)
  if usr
    redirect("/")
  else
    err = "Inloggning misslyckad"
    slim(:err, locals: { err: err })
  end
end

post("/users/new") do
  name = params[:name]
  email = params[:email]
  password = params[:password]
  password_confirm = params[:password_confirm]
  phone = params[:phonenumber]

  if password = password_confirm
    register_user(email, password, name, phone)
    redirect to("/login")
  else
    #felhantering (tempoärär)
    "The passwords were not the same"
  end
end

get ("/problem") do
  check_login()
  #om användaren är inloggad
  slim(:'problems/index')
end

get ("/orsaker") do
  check_login()
  
  slim(:'orsaker/index')
end

get ("/losningar") do
  # check_login()
  check_login()
  slim(:'losningar/index')
end

get("/users") do 
  check_login() # Kontrollera att användaren är inloggad
    cur_user_id = session[:userinfo]["uid"]
    users_list = users_show(cur_user_id)
    rights = get_rights(cur_user_id)

    slim(:'users/all', locals: { users: users_list, rights: rights})
end

get("/users/:id/show") do 
  userid = params[:id]
  uid = session[:userinfo]["uid"]
  uinfo = user_show(uid, userid)
  rights = get_rights(uid)
  levels = get_levels()
  
  slim(:'users/edit', locals: {user: uinfo, rights: rights, kategorier: levels})
end

post("/users/:id/update") do
  check_login()
  p params
  userid = params[:id].to_i
  uid = session[:userinfo]["uid"]
  name = params[:uname].strip
  email = params[:email].strip
  phone = params[:phone].strip
  levelid = params[:kategorin]

  user_update(uid, userid, name, email, phone, levelid)

  redirect('/users')
end

get("/users/:id/delete") do
  p params
  userid = params[:id]
  uid = session[:userinfo]["uid"]
  user_destroy(uid, userid)
  redirect('/users')
end

