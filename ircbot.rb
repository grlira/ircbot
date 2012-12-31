require 'socket'

load 'handler.rb'

class TCPSocket
    def gets_nb
        Kernel.puts 'gets_nb called'
        Thread.new do
            Kernel.puts 'starting thread'
            while line = gets
                yield line
            end
        end
    end
end

class IrcBot
    def initialize(address, port, nick)
        @address = address
        @port = port
        @nick = nick
        @connected = false
        @handler = Handler.new
    end

    def connect
        @socket = TCPSocket.new @address, @port
        @socket.gets_nb do |line|
            @handler.handle line, self
        end
        @socket.puts 'PASS password'
        @socket.puts "NICK #{@nick}"
        @socket.puts 'USER gustavo hostname servername :Gustavo Lira'
        @socket.puts 'JOIN #mieicstudents'
    end

    def privmsg(target, content)
        message = "PRIVMSG #{target} :#{content}"
        write message
    end

    def write(message)
        Kernel.puts "Writing #{message}"
        @socket.puts message
    end

    def disconnect
        @socket.puts "QUIT bye"
        @socket.close
    end

end

if ARGV.length != 3
    puts "Usage: <server> <port> <nick>"
    exit 1
end

bot = IrcBot.new ARGV[0], ARGV[1], ARGV[2]
bot.connect

while line = STDIN.gets.chomp
    if line == 'reload'
        load 'handler.rb'
    end
    if line == 'quit'
        bot.disconnect
        exit
    end
end
