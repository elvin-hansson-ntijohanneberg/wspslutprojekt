require "sqlite3"
require "bcrypt"

enable :sessions

module Model
  # Hämtar skeppsnamn med skeppid
  # @param [integer] sid Skeppets id
  # @return [string] Namnet på skeppet
  # @example get_ship(1) returnerar "Atlantica"

  def get_ship(sid)
    p sid
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    result = db.execute("SELECT title FROM system_orsaker WHERE sid =? AND parent = ?", [sid, 0]).first
    p result
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

  def register_user(email, password, name, phone)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    result = db.execute("SELECT email FROM users WHERE email=?", email).first
    p "Result: #{result}"
    if result != nil
      p "User already exists"
    else
      #Lägg till användare
      password_digest = BCrypt::Password.create(password)

      db.execute("INSERT INTO users (email, password, name, phone, level_id) VALUES (?,?,?,?,?)", [email, password_digest, name, phone, 1])
      session[:email] = email
    end
  end

  def get_rights(uid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    result = db.execute("SELECT users.uid, levels.* FROM users INNER JOIN levels ON users.level_id = levels.leid WHERE users.uid = ?;", [uid]).first

    return result
  end

  def users_show(uid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    rights = get_rights(uid)
    if rights["read"] == 1
      result = db.execute("SELECt uid, users.email, users.phone, users.name, levels.name as kategori FROM users INNER JOIN levels on users.level_id = levels.leid WHERE users.deleted = ?", [0])
      if result
        return result
      else
        return { "error" => "Inga användare" }
      end
    else
      return { "error" => "Inga läsrättigheter" }
    end
  end

  def get_levels()
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    result = db.execute("SELECT leid, name from levels")
    return result
  end

  def user_show(uid, userid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    rights = get_rights(uid) # kollar rights på aktiv användare
    p rights
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

  def user_update(uid, userid, name, email, phone, levelid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    rights = get_rights(uid) # kollar rights på aktiv användare
    if rights["write"] or rights["remove"] == 1
      db.execute("UPDATE users SET name = ?, email = ?, phone = ?, level_id = ? WHERE uid=?", [name, email, phone, levelid, userid])
    else
      return { "error" => "Inga läsrättigheter" }
    end
  end

  def user_destroy(uid, userid)
    db = SQLite3::Database.new("model/db/sxk.db")
    db.results_as_hash = true
    rights = get_rights(uid) # kollar rights på aktiv användare
    if rights["remove"] == 1
      result = db.execute("UPDATE users SET deleted = ? WHERE uid = ?", [1, userid])
      if result
        return result
      else
        return nil
      end
    else
      return { "error" => "Inga läsrättigheter" }
    end
  end
end
