require "sqlite3"
require "bcrypt"

enable :sessions

module Model
  # Hämtar skeppsnamn med skeppid
  # @param [integer] sid Skeppets id
  # @return [string] Namnet på skeppet
  # @example get_ship(1) returnerar "Atlantica"

  def get_ship(sid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    result = db.execute("SELECT title FROM system_orsaker WHERE sid =? AND parent = ?", [sid, 0]).first
    return result["title"]
  end

  # Loggar in användare
  # @param [string] email Användarens epostadress. Unik
  # @param [string] password Användarens lösenord.
  # @return [array] En array med användarinformation eller nil ifall misslyckad
  # @example login_user('elvin@mindmatter.se', 'MittLösenord') returnerar {'uid' => 1, 'name' => 'Elvin', 'email' => 'elvin@mindmatter.se', 'phone' => '0708889694' }

  def login_user(email, password)
    #db koppling
    #db hash
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users WHERE email=?", [email]).first

    if result
      #användaren finns
      pwd = result["password"]

      if BCrypt::Password.new(pwd) == password
        # lyckad inlogg annars error > felhantering
        usr = { "uid" => result["uid"], "name" => result["name"], "email" => result["email"], "phone" => result["phone"] }
        session[:userinfo] = usr
        session[:rights] = get_rights(usr["uid"])
        return usr
      else
        return nil
      end
    end
  end

  # Registrerar användare
  # @param [string] email Användarens epostadress. Unik
  # @param [string] password Användarens lösenord.
  # @param [string] name Användarens namn.
  # @param [string] phone Användarens telefon.
  # @return [array]  En hash med användarinfromation
  # @example login_user('elvin@mindmatter.se', 'MittLösenord') returnerar {'uid' => 1, 'name' => 'Elvin', 'email' => 'elvin@mindmatter.se', 'phone' => '0708889694' }

  def register_user(email, password, name, phone)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    result = db.execute("SELECT email FROM users WHERE email=?", email).first
    if result != nil
      flash[:error] = "Emailen är redan registrerad"
    else
      #Lägg till användare
      password_digest = BCrypt::Password.create(password)

      result = db.execute("INSERT INTO users (email, password, name, phone, level_id) VALUES (?,?,?,?,?)", [email, password_digest, name, phone, 1])
      return session[:email] = email
    end
  end

  # Hämtar rättigheter från databasen
  # @param [string] uid Användarens id. Unik
  # @return [array] En hash som väljer alla användarid och alla fält i levels som matchar det införda id
  # @example get_rights("1") returnerar {"uid"=>1, "leid"=>4, "name"=>"Kapten", "read"=>1, "write"=>1, "remove"=>1}
  def get_rights(uid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    result = db.execute("SELECT users.uid, levels.* FROM users INNER JOIN levels ON users.level_id = levels.leid WHERE users.uid = ?;", [uid]).first
    return result
  end

  # Visar alla användare
  # @param [string] uid Användarens id. Unik
  # @return [array] En hash som väljer alla användarid, email, telefon, namn och level namn (rang) med inner join eller "error" => "Inga användare"  ifall det inte finns några användare eller "error" => "Inga läsrättigheter" ifall man inte har rättigheter att se
  # @example users_show("1") returnerar {"uid"=>1, "email"=>"elvin@mindmatter.se", "phone"=>"0708889694", "name"=>"Elvin Hansson", "kategori"=>"Kapten"}, {"uid"=>2, "email"=>"mh@mindmatter.se", "phone"=>"0708202825", "name"=>"Mats Hansson", "kategori"=>"Elev"}
  def users_show(uid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    rights = get_rights(uid)
    if rights["read"] == 1
      result = db.execute("SELECT uid, users.email, users.phone, users.name, levels.name as kategori FROM users INNER JOIN levels on users.level_id = levels.leid WHERE users.deleted = ?", [0])
      if result
        return result
      else
        return { "error" => "Inga användare" }
      end
    else
      return { "error" => "Inga läsrättigheter" }
    end
  end

  # Hämtar alla nivåer
  # @return [array] En hash som
  # @example get_rights() returnerar {"leid"=>1, "name"=>"Gäst"}, {"leid"=>2, "name"=>"Elev"}, {"leid"=>3, "name"=>"Bås"}, {"leid"=>4, "name"=>"Kapten"}

  def get_levels()
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    result = db.execute("SELECT leid, name from levels ORDER BY leid")
    return result
  end

  # Visar användare (singular)
  # @param [string] uid Användarens id. Unik
  # @param [string] userid Den valda användarens id
  # @return [array] En hash som väljer den valda användarens id, email, telefon, namn, nivå id och nivå namn.
  # @example get_rights("1, 1") returnerar {"uid"=>1, "email"=>"elvin@mindmatter.se", "phone"=>"0708889694", "name"=>"Elvin Hansson", "kategoriId"=>4, "kategori"=>"Kapten"}
  def user_show(uid, userid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    rights = get_rights(uid) # kollar rights på aktiv användare
    if rights["write"] == 1 || rights["remove"] == 1
      result = db.execute("SELECT uid, users.email, users.phone, users.name, levels.leid as kategoriId, levels.name as kategori FROM users INNER JOIN levels on users.level_id = levels.leid WHERE uid =?", [userid]).first
      if result
        return result
      else
        return nil
      end
    else
      return { "error" => "Inga läsrättigheter" }
    end
  end

  # Updaterar användaren i databasen
  # @param [string] uid Användarens id. Unik
  # @param [string] userid Den valda användarens id
  # @param [string] name den valda användarns namn
  # @param [string] email Den valda användarens email
  # @param [string] phone Den valda användarens telefon
  # @param [string] levelid Den valda användarens nivå id
  # @return [array] En hash som
  # @example get_rights("1") returnerar {"uid"=>1, "leid"=>4, "name"=>"Kapten", "read"=>1, "write"=>1, "remove"=>1}
  def user_update(uid, userid, name, email, phone, levelid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    rights = get_rights(uid) # kollar rights på aktiv användare
    if rights["write"] or rights["remove"] == 1
      result = db.execute("UPDATE users SET name = ?, email = ?, phone = ?, level_id = ? WHERE uid=?", [name, email, phone, levelid, userid])
      p result
    else
      return { "error" => "Inga läsrättigheter" }
    end
  end

  # "Raderar" en användare men egentligen raderar jag bara personuppgifterna
  # @param [string] uid Användarens id
  # @param [string] userid Den valda användarens id
  # @return [array] En hash som returnar antingen en tom hash som blir true, ingenting eller ett felmeddelande
  # @example user_destroy(1, 3) returnerar []
  def user_destroy(uid, userid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    rights = get_rights(uid) # kollar rights på aktiv användare
    cur_user = user_show(uid, userid)
    if rights["remove"] == 1
      result = db.execute("UPDATE users SET deleted = ?, phone = ?, name = ?, password = ?, email = ? WHERE uid = ? ", [1, "Raderad användare", "Finns ej", "Finns ej", "Finns ej", userid])
      if result
        return result
      else
        return nil
      end
    else
      return { "error" => "Inga läsrättigheter" }
    end
  end

  # @param [string] uid Användarens id
  # @param [string] uid Användarens id
  # @param [string] uid Användarens id
  # @param [string] uid Användarens id
  # @return [array] En hash som
  # @example get_rights() returnerar {"leid"=>1, "name"=>"Gäst"}, {"leid"=>2, "name"=>"Elev"}, {"leid"=>3, "name"=>"Bås"}, {"leid"=>4, "name"=>"Kapten"}
  def check_children_o?(sid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    children = db.execute("SELECT sid FROM system_orsaker WHERE parent = ?", [sid])
    return children.any?
  end

  # @param [string] uid Användarens id
  # @return [array] En hash som
  # @example
  def get_orsaker(sid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM system_orsaker WHERE parent = ? ORDER BY delsystem, title ASC", [sid])
    return result
  end

  # @param [string] uid Användarens id
  # @param [string] uid Användarens id
  # @param [string] uid Användarens id
  # @param [string] uid Användarens id
  # @return [array] En hash som
  # @example get_rights() returnerar {"leid"=>1, "name"=>"Gäst"}, {"leid"=>2, "name"=>"Elev"}, {"leid"=>3, "name"=>"Bås"}, {"leid"=>4, "name"=>"Kapten"}
  def get_orsak(sid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM system_orsaker WHERE sid = ?", [sid]).first
    p result
    return result
  end

  # @param [string] uid Användarens id
  # @param [string] uid Användarens id
  # @param [string] uid Användarens id
  # @param [string] uid Användarens id
  # @return [array] En hash som
  # @example get_rights() returnerar {"leid"=>1, "name"=>"Gäst"}, {"leid"=>2, "name"=>"Elev"}, {"leid"=>3, "name"=>"Bås"}, {"leid"=>4, "name"=>"Kapten"}
  def orsak_new(parent, title, description, delsystem)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    result = db.execute("INSERT INTO system_orsaker (parent, title, description, delsystem) VALUES (?, ?, ?, ?)", [parent, title, description, delsystem])
    return result
  end

  # @param [string] uid Användarens id
  # @param [string] uid Användarens id
  # @param [string] uid Användarens id
  # @param [string] uid Användarens id
  # @return [array] En hash som
  # @example get_rights() returnerar {"leid"=>1, "name"=>"Gäst"}, {"leid"=>2, "name"=>"Elev"}, {"leid"=>3, "name"=>"Bås"}, {"leid"=>4, "name"=>"Kapten"}
  def orsak_update(sid, title, description, delsystem)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    result = db.execute("UPDATE system_orsaker SET title = ?, description = ?, delsystem = ? WHERE sid = ? ", [title, description, delsystem, sid])
    return result
  end

  # @param [string] uid Användarens id
  # @param [string] uid Användarens id
  # @param [string] uid Användarens id
  # @param [string] uid Användarens id
  # @return [array] En hash som
  # @example get_rights() returnerar {"leid"=>1, "name"=>"Gäst"}, {"leid"=>2, "name"=>"Elev"}, {"leid"=>3, "name"=>"Bås"}, {"leid"=>4, "name"=>"Kapten"}
  def get_orsak_path(sid, path = [], db = nil)
    db ||= SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true

    result = db.execute("SELECT * FROM system_orsaker WHERE sid = ?", [sid]).first

    # Lägg till aktuella posten i vår path.
    # Observera att vi här antar att du vill du ha en hash med nycklarna :sid och :rubrik

    path.unshift({ sid: result["sid"], title: result["title"] })
    # Om parent är 0, är vi vi roten och kan returnera uppsamlade path.
    if result["parent"] == 0
      return path
    else
      # Annars, rekursivt kalla på funktionen med förälderns sid.
      get_orsak_path(result["parent"], path, db)
    end
  end

  def get_children_orsaker(sid, db = nil, details = [])
    db ||= SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
  end

  # @param [string] uid Användarens id
  # @param [string] uid Användarens id
  # @param [string] uid Användarens id
  # @param [string] uid Användarens id
  # @return [array] En hash som
  # @example get_rights() returnerar {"leid"=>1, "name"=>"Gäst"}, {"leid"=>2, "name"=>"Elev"}, {"leid"=>3, "name"=>"Bås"}, {"leid"=>4, "name"=>"Kapten"}
  def orsak_destroy(uid, sid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    rights = get_rights(uid)

    if rights["remove"] == 1
      if check_children_o?(sid)
        flash[:error] = "Orsak har underliggande orsaker, kan ej tas bort"
        return false
      else
        db.execute("DELETE FROM system_orsaker WHERE sid = ?", [sid])
        return true
      end
    else
      flash[:error] = "Inga rättigheter"
    end
  end

  def get_delsystems()
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM delsystem")
    return result
  end

  # Visar alla barnproblem under ett valt problem
  # @param [string] pid Det valda problemets id
  # @return [array] En hash som ger alla problem id under en parent
  # @example get_rights() returnerar {"leid"=>1, "name"=>"Gäst"}, {"leid"=>2, "name"=>"Elev"}, {"leid"=>3, "name"=>"Bås"}, {"leid"=>4, "name"=>"Kapten"}
  def check_children_p?(pid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    children = db.execute("SELECT pid FROM problem WHERE parent = ?", [pid])
    return children.any?
  end

  #
  # @param [string] pid Det valda problemets id
  # @return [array] En hash som ger alla problem id under en parent
  # @example get_rights() returnerar {"leid"=>1, "name"=>"Gäst"}, {"leid"=>2, "name"=>"Elev"}, {"leid"=>3, "name"=>"Bås"}, {"leid"=>4, "name"=>"Kapten"}
  def get_problems(pid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM problem WHERE parent = ? ORDER BY title ASC", [pid])
    p result
    return result
  end

  def get_problem(pid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM problem WHERE pid = ?", [pid]).first
    p result
    return result
  end

  def problem_new(parent, title, description)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    result = db.execute("INSERT INTO problem (parent, title, description) VALUES (?, ?, ?)", [parent, title, description])
    return result
  end

  def problem_update(pid, title, description)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    result = db.execute("UPDATE problem SET title = ?, description = ? WHERE pid = ?", [title, description, pid])
    return result
  end

  def get_problem_path(pid, path = [], db = nil)
    db ||= SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true

    result = db.execute("SELECT * FROM problem WHERE pid = ?", [pid]).first
    p pid
    p result
    # Lägg till aktuella posten i vår path.
    # Observera att vi här antar att du vill du ha en hash med nycklarna :sid och :rubrik

    path.unshift({ pid: result["pid"], title: result["title"] })
    # Om parent är 0, är vi vi roten och kan returnera uppsamlade path.
    if result["parent"] == 0
      return path
    else
      # Annars, rekursivt kalla på funktionen med förälderns sid.
      get_problem_path(result["parent"], path, db)
    end
  end

  def problem_destroy(uid, pid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    rights = get_rights(uid)

    if rights["remove"] == 1
      if check_children_p?(pid)
        flash[:error] = "Problem har underliggande problem, kan ej tas bort"
        return false
      else
        db.execute("DELETE FROM problem WHERE pid = ?", [pid])
        return true
      end
    else
      flash[:error] = "Inga rättigheter"
    end
  end

  def get_c_orsaker(sid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM system_orsaker WHERE parent = ? AND parent <> ? ORDER BY delsystem, title ASC", [sid, 0])

    return result
  end

  def get_c_problems(pid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM problem WHERE parent = ? AND parent <> ? ORDER BY title ASC", [pid, 0])
    return result
  end

  def get_c_connections()
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM problemsystem")
    return result
  end

  def connections_update(relations, uid)
    check_login()
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    relations.each do |problem_id, systems|
      systems.each do |system_id, value|
        if value == "1"
          existing_relation = db.execute("SELECT * FROM ProblemSystem WHERE ProblemId = ? AND SystemId = ?", [problem_id, system_id]).first
          if existing_relation.nil?
            db.execute("INSERT INTO problemsystem (userid, problemid, systemid) VALUES (?, ?, ?)", [uid, problem_id, system_id])
          end
        else
          db.execute("DELETE FROM problemsystem WHERE problemid = ? AND systemid = ?", [problem_id, system_id])
        end
      end
    end
  end

  def get_problemsystem(pid, sid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    problem_system = db.execute("SELECT psid, problem.title as p, system_orsaker.title as o, problemsystem.problemid, problemsystem.systemid FROM problemsystem INNER JOIN system_orsaker ON problemsystem.systemid = system_orsaker.sid INNER JOIN problem ON problemsystem.problemid = problem.pid WHERE problemid=? and systemid=?", [pid, sid]).first
    return problem_system
  end

  def get_losningar(psid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    solution = db.execute("SELECT * FROM losningar where psid = ?", [psid]).first
    return solution
  end

  def get_attachments(psid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    attachments = db.execute("SELECT aid, file, imgtitle, users.name, users.phone, users.email FROM attachments INNER JOIN users on attachments.userid=users.uid where psid = ?", [psid])
    return attachments
  end

  def save_file(file)
    filetype = file[:type]
    tmpfile = file[:tempfile]
    name = file[:filename]
    directory = "public/uploads/attachments/"

    path = File.join(directory, name)

    FileUtils.mkdir_p(directory) unless File.exist?(directory)
    File.open(path, "wb") { |f| f.write(tmpfile.read) }

    webpath = "/uploads/attachments/#{name}"
    webpath = webpath.encode("UTF-8")

    return webpath
  end

  def attachment_new(psid, webpath, filetype, imgtitle, uid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    db.execute("INSERT INTO attachments (psid, file, filetype, imgtitle, userid) values (?, ?, ?, ?, ?)", [psid, webpath, filetype, imgtitle, uid])
  end

  def attachment_delete(uid, aid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    rights = get_rights(uid)
    if rights["remove"] == 1
      db.execute("DELETE FROM attachments WHERE aid = ?", [aid])
    else
      flash[:error] = "Inga raderarättigheter"
    end
  end

  def losningar_new(psid, title, description, uid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true

    db.execute("INSERT INTO losningar (psid, title, description, userid) VALUES (?, ?, ?, ?)", psid, title, description, uid)
  end

  def losningar_update(title, description, uid, psid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true

    db.execute("UPDATE losningar SET title=?, description=?, userid=? WHERE psid=?", [title, description, uid, psid])
  end
end
