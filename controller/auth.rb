def check_login()
    user = session[:userinfo]
    if user
        return true
    else
        redirect("/login")
        return false
    end
end