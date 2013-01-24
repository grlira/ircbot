require_relative 'database'
require_relative 'handler'
require_relative '../ircbot'
require_relative '../kickstart'

if ARGV.length < 2
    puts "Usage: bot <conffile> <db>"
    exit
end
db = Parrot::Database.new(ARGV[1])
IRC::Bot.kickstart ARGV[0], Parrot::Handler.new(db)
at_exit { db.close }