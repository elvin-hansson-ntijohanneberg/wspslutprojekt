require "slim"
require "sinatra"
require "sinatra/reloader"
require "sinatra/flash"
require_relative "./model/model.rb"
require_relative "./controller/auth.rb"

enable :sessions

include Model

get ("/") do
  userinfo = session[:userinfo]

  slim(:index, locals: { user: userinfo })
end

get ("/ship/:id") do
  check_login()
  session[:shipid] = params[:id].to_i
  session[:shipname] = get_ship(params[:id].to_i)
  slim(:ship, locals: { shid: session[:shipid], shname: session[:shipname] })
end

get ("/users/new") do
  slim(:'users/new')
end

get ("/login") do
  slim(:'users/index', locals: { email: session[:email] })
end

get ("/logout") do
  session.clear
  flash[:notice] ="Du är utloggad"
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

get ("/problems") do
  check_login()  
  pid = session[:shipid]
  result = get_problem(pid)
  current_system = result["pid"]
  current_system_name = result["title"]
  current_system_description = result["description"]

  orsaker = get_problems(sid)

  if orsaker.empty?
    orsaker = [{ "sid" => 0, "title" => "Inga undersystem", "parent" => current_system }]
  end
  p orsaker
  slim(:'orsaker/index', locals: { orsaker: orsaker, current_system_name: current_system_name, current_system: current_system, current_system_description: current_system_description })
  slim(:'problems/index')
end

get("/problems/search") do 
  check_login()
  #om användaren är inloggad
  slim(:'problems/search')
end

get ("/orsaker") do
  check_login()
  sid = session[:shipid]
  path = get_orsak_path(sid)
  result = get_orsak(sid)
  current_system = result["sid"]
  current_system_name = result["title"]
  current_system_description = result["description"]

  orsaker = get_orsaker(sid)

  if orsaker.empty?
    orsaker = [{ "sid" => 0, "title" => "Inga undersystem", "parent" => current_system }]
  end
  p orsaker
  slim(:'orsaker/index', locals: { path: path, orsaker: orsaker, current_system_name: current_system_name, current_system: current_system, current_system_description: current_system_description })
end

get ("/orsaker/:sid/show") do
  check_login()
  sid = params[:sid]
  path = get_orsak_path(sid)
  result = get_orsak(sid)
  current_system = result["sid"]
  current_system_name = result["title"]
  current_system_description = result["description"]

  orsaker = get_orsaker(sid)

  if orsaker.empty?
    orsaker = [{ "sid" => 0, "title" => "Inga undersystem", "parent" => current_system }]
  end
  p orsaker
  slim(:'orsaker/index', locals: { path: path, orsaker: orsaker, current_system_name: current_system_name, current_system: current_system, current_system_description: current_system_description })
end

post("/orsaker/:parent/new") do
  parent = params[:parent].to_i
  title = params[:title]
  description = params[:description]
  orsak = orsak_new(parent, title, description)

  redirect("/orsaker")
end

post("/orsaker/:sid/update") do
  sid = params[:sid]
  title = params[:title]
  description = params[:description]

  result = orsak_update(sid, title, description)

  redirect("/orsaker")
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

  slim(:'users/all', locals: { users: users_list, rights: rights })
end

get("/users/:id/show") do
  userid = params[:id]
  uid = session[:userinfo]["uid"]
  uinfo = user_show(uid, userid)
  rights = get_rights(uid)
  levels = get_levels()

  slim(:'users/edit', locals: { user: uinfo, rights: rights, kategorier: levels })
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

  redirect("/users")
end

get("/users/:id/delete") do
  p params
  userid = params[:id]
  uid = session[:userinfo]["uid"]
  user_destroy(uid, userid)
  redirect("/users")
end
