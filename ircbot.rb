require 'socket'

module IRC
    
    class Bot
        attr_reader :nick, :connected, :channels, :users

        def nick_in_use
            puts "Error: nick #{@nick} is in use on server"
            disconnect
        end
        
        DEFAULT_OPTIONS = {port: 6667, encoding: 'UTF-8'}

        def initialize(options = {})
            options = DEFAULT_OPTIONS.merge(options)
            @address = options[:server]
            @port = options[:port]
            @nick = options[:nick]
            @shortname = options[:shortname]
            @longname = options[:longname]
            @encoding = options[:encoding]
            @connected = false
            @handler = options[:handler]
            @handler.kernel = self
            @channels = {}
            @users = {}
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
            @socket.set_encoding @encoding, 'UTF-8'
            @socket.puts 'PASS password'
            @socket.puts "NICK #{@nick}"
            @socket.puts "USER #@shortname hostname servername :#@longname"
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
        
        def read_loop
            until @socket.closed?
                begin
                    yield @socket.gets
                rescue StandardError => exception
                    Kernel.puts "#{exception.inspect}\n#{exception.backtrace.join "\n"}"
                end
            end
        end
        
        def run_main_loop
            read_loop {|line| @handler.handle line}
        end

        def disconnect
            @socket.puts "QUIT bye"
            @socket.close
            @connected = false
        end
    end
end

if __FILE__ == $0
    if ARGV.length < 1
        puts "Usage: ircbot <configuration-file>"
        exit
    end
    require_relative 'kickstart'
    require_relative 'standard_handler'
    IRC::Bot.kickstart ARGV[0], IRC::StandardHandler.new
end