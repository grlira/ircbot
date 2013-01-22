require 'thread'
require_relative 'database'
require_relative '../handler'

module Parrot
    
    class Handler < IRC::Handler
        # The range of times that the handler may take before emitting a message on its own or as a reply.
        STANDALONE_INTERVAL = 10..60
        REPLY_INTERVAL = 1..3
        
        def initialize(database)
            @db = database
            @queue = Queue.new
            Thread.new do
                loop do
                    @queue.pop
                    speak
                end
            end
            # Regularly send out a message
            Thread.new do
                loop do
                   sleep rand(STANDALONE_INTERVAL)
                   @queue << nil
                end
            end
        end
        
        def speak
            return if @kernel.channels.empty?
            @kernel.privmsg @kernel.channels.keys.first, @db.gen_block
        end
        
        def handle_chat(message)
            @db.process message.content
            Thread.new do
                sleep rand(REPLY_INTERVAL)
                @queue << nil
            end
        end
    end
end

if __FILE__ == $0
    if ARGV.length < 4
        puts "Usage: bot <server> <port> <name> <db>"
        exit
    end
    
    require_relative '../ircbot'
    bot = IRC::Bot.new *ARGV[0..2], Parrot::Handler.new(Parrot::Database.new(ARGV[3]))
    bot.connect
    bot.join_channel "#mieicstudents"
    STDIN.gets
end