require 'mysql2'
class Handler
    def run(req)
        db = Mysql2::Client.new(:host => ENV["MYSQL_HOST"],
                                 :username => ENV["MYSQL_USER"],
                                 :password => ENV["MYSQL_PASS"],
                                 :database => ENV["MYSQL_DB"], 
                                 :reconnect => true)
        q = db.prepare("delete from users where name = ?")
        q.execute(req)
        db.close
        return "Delete users: #{req} from DB: #{ENV["MYSQL_HOST"]}"
    end
end
