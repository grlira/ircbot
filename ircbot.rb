require 'socket'
require 'pp'

load 'handler.rb'

class TCPSocket
    def gets_nb
        Thread.new do
            while !closed?
                begin
                    yield gets
                rescue StandardError => exception
                    Kernel.puts "#{exception.inspect}\n#{exception.backtrace.join "\n"}"
                end
            end
        end
    end
end

module IRC
    class Bot
        attr_reader :nick, :connected, :channels

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
            @channels = {}
        end

        def join_channel(channel)
            write "JOIN #{channel}"
        end

        def part_channel(channel)
            if @channels[channel]
                write "PART #{channel}"
                @channels[channel] = nil
            end
        end

        def connect
            @socket = TCPSocket.new @address, @port
            @socket.gets_nb do |line|
                @handler.handle line
            end
            @socket.puts 'PASS password'
            @socket.puts "NICK #{@nick}"
            @socket.puts 'USER gustavo hostname servername :Gustavo Lira'
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
end

if ARGV.length != 3
    puts "Usage: <server> <port> <nick>"
    exit 1
end

bot = IRC::Bot.new *ARGV[0..2]
bot.connect
bot.join_channel "#mieicstudents"

while bot.connected
    line = STDIN.gets.chomp
    case line
    when 'reload'
        load 'handler.rb'
    when 'quit'
        bot.disconnect
    end
end
