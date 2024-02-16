require 'sqlite3'
require 'bcrypt'

def login_user (password, name)
    #db koppling
    #db hash
    db = SQLite3::Database.new('model/db/sxk.db')
    db.results_as_hash = true
    result = db.execute('SELECT * FROM users WHERE name=?', name).first
    if result != nil
      pwd = result["password"]
      if BCrypt::Password.newU(pwd) == password
        return { "uid" => result["uid"], "name" => result["name"], "phone" => result["phone"]}
      else
        return nil
      end
    else

    end 
    #logga in användare och returnera id om lyckat inlogg annars error > felhantering
    return id
end

def register_user (password, name, phone)
    db = SQLite3::Database.new('model/db/sxk.db')
    db.results_as_hash = true
    result = db.execute('SELECT name FROM users WHERE name=?', name).first
  p "Result: #{result}"
  if result != nil
    p "User already exists"
    
  else
      #Lägg till användare
      password_digest = BCrypt::Password.create(password)
      db.execute('INSERT INTO users (name, password, phone) VALUES (?,?,?)',name, password_digest, phone)
   end
end