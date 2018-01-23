require 'mysql2'
class Handler
    def run(req)
        db = Mysql2::Client.new(:host => ENV["MYSQL_HOST"],
                                 :username => ENV["MYSQL_USER"],
                                 :password => ENV["MYSQL_PASS"],
                                 :database => ENV["MYSQL_DB"], 
                                 :reconnect => true)
        q = db.prepare("insert into users set name = ?, date = now()")
        q.execute(req)
        db.close
        return "Saved user: #{req} to DB: #{ENV["MYSQL_HOST"]}"
    end
end
