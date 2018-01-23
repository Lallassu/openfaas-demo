require 'mysql2'
class Handler
    def run(req)
        db = Mysql2::Client.new(:host => ENV["MYSQL_HOST"],
                                 :username => ENV["MYSQL_USER"],
                                 :password => ENV["MYSQL_PASS"],
                                 :database => ENV["MYSQL_DB"], 
                                 :reconnect => true)
        q = db.prepare("select * from users")
        res = q.execute()
        users = []
        res.each(:as => :array) do |u|
            users << [u["name"], u["date"]]
        end
        return users
    end
end
