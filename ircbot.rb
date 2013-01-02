require 'socket'
require 'pp'

load 'handler.rb'

class TCPSocket
    def gets_nb
        Thread.new do
            begin
                while !closed?
                    yield gets
                end
            rescue
                pp $!
            end
        end
    end
end

class IrcBot

    attr_reader :nick, :connected

    def nick_in_use
        puts "Error: nick #{@nick} is in use on server"
        disconnect
    end

    def initialize(address, port, nick)
        @address = address
        @port = port
        @nick = nick
        @connected = false
        @handler = Handler.new self
    end

    def connect
        @socket = TCPSocket.new @address, @port
        @socket.gets_nb do |line|
            @handler.handle line
        end
        @socket.puts 'PASS password'
        @socket.puts "NICK #{@nick}"
        @socket.puts 'USER gustavo hostname servername :Gustavo Lira'
        @socket.puts 'JOIN #mieicstudents'
        @connected = true
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
        @connected = false
        exit
    end
    
end

if ARGV.length != 3
    puts "Usage: <server> <port> <nick>"
    exit 1
end

bot = IrcBot.new *ARGV[0..2]
bot.connect

while bot.connected
    line = STDIN.gets.chomp
    case line
    when 'reload'
        load 'handler.rb'
    when 'quit'
        bot.disconnect
    end
end
