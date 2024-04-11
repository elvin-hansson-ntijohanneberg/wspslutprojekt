require "slim"
require "sinatra"
require "sinatra/reloader"
require "sinatra/flash"
require "redcarpet"
require_relative "./model/model.rb"
require_relative "./controller/auth.rb"

enable :sessions

include Model

# Rotsidan, den sidan som man först når
#
# @return [Slim::Template] En local variabel med användarinfo
get ("/") do
  userinfo = session[:userinfo]

  slim(:index, locals: { user: userinfo })
end

# Härledande sida som är baserad på vilken av båtarna du väljer
#
# @param [string] id, skeppets id
# @see Model#check_login
# @return [Slim::Template]

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

# return [void]

get ("/logout") do
  session.clear
  flash[:notice] = "Du är utloggad"
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
  pid = 1
  path = get_problem_path(pid)
  result = get_problem(pid)
  current_problem = result["pid"]
  current_problem_name = result["title"]
  current_problem_description = result["description"]

  problems = get_problems(pid)
  chkchildren = check_children_p?(current_problem)

  slim(:'problems/index', locals: { path: path, chkchildren: chkchildren, problems: problems, current_problem_name: current_problem_name, current_problem: current_problem, current_problem_description: current_problem_description })
end

get ("/problems/:pid/show") do
  check_login()
  pid = params[:pid]
  path = get_problem_path(pid)
  result = get_problem(pid)
  current_problem = result["pid"]
  current_problem_name = result["title"]
  current_problem_description = result["description"]

  problems = get_problems(pid)
  chkchildren = check_children_p?(current_problem)

  slim(:'problems/index', locals: { path: path, chkchildren: chkchildren, problems: problems, current_problem_name: current_problem_name, current_problem: current_problem, current_problem_description: current_problem_description })
end

post("/problems/:parent/new") do
  parent = params[:parent].to_i
  title = params[:title]
  description = params[:description]
  problem = problem_new(parent, title, description)

  redirect("/problems")
end

post("/problems/:pid/update") do
  pid = params[:pid]
  title = params[:title]
  description = params[:description]

  result = problem_update(pid, title, description)

  redirect("/problems")
end

get("/problems/:id/delete") do
  check_login()
  pid = params[:id].to_i
  result = get_problem(pid)
  parent = result["parent"]
  res = problem_destroy(session[:userinfo]["uid"], pid)

  if res
    flash[:notice] = "Raderat problem"
  end
  redirect("/problems/#{parent}/show")
end

get("/problemsolving") do
  check_login()
  #om användaren är inloggad
  uid = session[:userinfo]["uid"]
  shid = session[:shipid]
  problems = get_c_problems(1)
  orsaker = get_c_orsaker(shid)
  connections = get_c_connections()
  rights = get_rights(uid)
  slim(:'problemsolving/index', locals: { problems: problems, orsaker: orsaker, connections: connections, rights: rights })
end

get ("/orsaker") do
  check_login()
  sid = session[:shipid]
  path = get_orsak_path(sid)
  result = get_orsak(sid)
  current_system = result["sid"]
  current_system_name = result["title"]
  current_system_description = result["description"]
  current_system_delsystem = result["delsystem"]

  orsaker = get_orsaker(sid)
  chkchildren = check_children_o?(current_system)

  slim(:'orsaker/index', locals: { path: path, chkchildren: chkchildren, orsaker: orsaker, current_system_name: current_system_name, current_system: current_system, current_system_description: current_system_description, current_system_delsystem: current_system_delsystem, delsystems: get_delsystems() })
end

get ("/orsaker/:sid/show") do
  check_login()
  sid = params[:sid]
  path = get_orsak_path(sid)
  result = get_orsak(sid)
  current_system = result["sid"]
  current_system_name = result["title"]
  current_system_description = result["description"]
  current_system_delsystem = result["delsystem"]

  orsaker = get_orsaker(sid)
  chkchildren = check_children_o?(current_system)

  slim(:'orsaker/index', locals: { path: path, chkchildren: chkchildren, orsaker: orsaker, current_system_name: current_system_name, current_system: current_system, current_system_description: current_system_description, current_system_delsystem: current_system_delsystem, delsystems: get_delsystems() })
end

post("/orsaker/:parent/new") do
  parent = params[:parent].to_i
  title = params[:title]
  description = params[:description]
  delsystem = params[:delsystem]
  orsak = orsak_new(parent, title, description, delsystem)

  redirect("/orsaker")
end

post("/orsaker/:sid/update") do
  sid = params[:sid]
  title = params[:title]
  description = params[:description]
  delsystem = params[:delsystem]
  result = orsak_update(sid, title, description, delsystem)

  redirect("/orsaker")
end

get("/orsaker/:id/delete") do
  check_login()
  sid = params[:id].to_i
  result = get_orsak(sid)
  parent = result["parent"]
  res = orsak_destroy(session[:userinfo]["uid"], sid)

  if res
    flash[:notice] = "Raderad orsak"
  end
  redirect("/orsaker/#{parent}/show")
end

get("/losningar") do
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
  userid = params[:id]
  uid = session[:userinfo]["uid"]
  user_destroy(uid, userid)
  redirect("/users")
end

get("/connections") do
  check_login()
  uid = session[:userinfo]["uid"]
  shid = session[:shipid]
  problems = get_c_problems(1)
  orsaker = get_c_orsaker(shid)
  p orsaker
  connections = get_c_connections()
  rights = get_rights(uid)
  slim(:'connections/index', locals: { problems: problems, orsaker: orsaker, connections: connections, rights: rights })
end

post("/connections/update") do
  check_login()
  relations = params[:relation]
  uid = session[:userinfo]["uid"]
  p relations
  connections_update(relations, uid)

  redirect("/connections")
end

get("/losningar/:pid/:sid") do

  check_login()
  pid = params[:pid]
  sid = params[:sid]

  uid = session[:userinfo]["uid"]
  rights = get_rights(uid)

  problem_system = get_problemsystem(pid, sid)
  solution = get_losningar(problem_system["psid"])

  if solution
    markdown_renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML)# Hämtat från redcarpet guide på github
    description = markdown_renderer.render(solution["description"])
    solution["description_md"] = description
  end

  attachments = get_attachments(problem_system["psid"])

  slim(:"/losningar/index", locals: { rights: rights, solution: solution, problem_system: problem_system, attachments: attachments })
end
get ("/losningar/:pid/:sid/edit") do
  check_login()
  pid = params[:pid]
  sid = params[:sid]

  uid = session[:userinfo]["uid"]
  rights = get_rights(uid)

  problem_system = get_problemsystem(pid, sid)
  solution = get_losningar(problem_system["psid"])

  if solution
    markdown_renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    description = markdown_renderer.render(solution["description"])
    solution["description_md"] = description
  end

  attachments = get_attachments(problem_system["psid"])

  slim(:"/losningar/edit", locals: { rights: rights, solution: solution, problem_system: problem_system, attachments: attachments })
end

post("/losningar/:pid/:sid/new") do
  check_login()
  uid = session[:userinfo]["uid"]
  psid = params[:psid].to_i
  pid = params[:pid].to_i
  sid = params[:sid].to_i
  title = params[:title]
  imgtitle = params[:imgtitle]
  description = params[:description]

  file = params[:file]
  p params
  filetype = file[:type]
  filename = file[:filename]
  tmpfile = file[:tempfile]

  unless file && tmpfile && filename 
    return "Filuppladdning misslyckades."
  end
  webpath = save_file(file)
  attachment_new(psid, webpath, filetype, imgtitle, uid)
  losningar_new( psid, title, description, uid)
  
  redirect ("/losningar/#{pid}/#{sid}")
end

post "/losningar/:pid/:sid/update" do
  check_login()
  psid = params[:psid].to_i
  pid = params[:pid].to_i
  sid = params[:sid].to_i
  uid = session[:userinfo]["uid"]
  title = params[:title]
  imgtitle = params[:imgtitle]
  description = params[:description]

  losningar_update(title, description, uid, psid)

  redirect ("/losningar/#{pid}/#{sid}")
end

post ("/losningar/:pid/:sid/new_attachment") do
  check_login()
  uid = session[:userinfo]["uid"]
  psid = params[:psid].to_i
  pid = params[:pid].to_i
  sid = params[:sid].to_i
  title = params[:title]
  imgtitle = params[:imgtitle]
  

  file = params[:file]
  filetype = params[:file][:type]
  filename = file[:filename]
  tmpfile = params[:file][:tempfile]

  unless file && tmpfile && filename
    return "Filuppladdning misslyckades."
  end
  webpath = save_file(file)
  attachment_new(psid, webpath, filetype, imgtitle, uid)
  
  redirect ("/losningar/#{pid}/#{sid}")
end

get ("/losningar/:pid/:sid/:aid/delete") do
  check_login()
  pid = params[:pid].to_i
  sid = params[:sid].to_i
  aid = params[:aid].to_i
  #pp params
  res = attachment_delete(session[:userinfo]["uid"], aid)

  if res
    flash[:notice] = "Raderad attachment"
  end
  redirect ("/losningar/#{pid}/#{sid}/edit")
end
