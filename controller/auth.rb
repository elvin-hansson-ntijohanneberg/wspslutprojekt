def check_login()
    user = session[:userinfo]
    if user
        return true
    else
        redirect("/login")
        return false
    end
end

def valid_password?(password)
    min_length = 8

    has_uppercase = /[A-Z]+/.match?(password)
    has_lowercase = /[a-z]+/.match?(password)
    has_digit = /\d+/.match?(password)
    has_special_char = /[\!\@\#\$\%\^\&\*\(\)\_\+\-\=\{\}\[\]\|\;\:\'\"\>\<\,\.\+\/]+/.match?(password)

    if password.length >= min_length && has_uppercase && has_lowercase && has_digit && has_special_char
        true
    else
        false
    end
end

def valid_email?(email)
    regex = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
    email.match?(regex)
end