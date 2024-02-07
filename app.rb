require 'slim' 
require 'sinatra' 
require 'sqlite3'
require 'bcrypt'



get ('/') do 
    slim(:index)
end