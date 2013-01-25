require 'thread'
require_relative 'database'
require_relative '../handler'

module Parrot
    class Handler < IRC::Handler
        # The range of times that the handler may take before emitting a message on its own or as a reply.
        STANDALONE_INTERVAL = 10..60
        REPLY_INTERVAL = 1..5
        
        def self.source_location
            __FILE__
        end
        
        def initialize(database)
            @db = database
            @queue = Queue.new
            @quiet = false
            Thread.new do
                loop do
                    @queue.pop
                    begin
                        speak
                    rescue
                        p$!
                    end
                end
            end
            # Regularly send out a message
            Thread.new do
                loop do
                   sleep rand(STANDALONE_INTERVAL)
                   @queue << nil unless @quiet
                end
            end
        end
        
        def speak
            return if @kernel.channels.empty?
            @kernel.privmsg @kernel.channels.keys.first, @db.gen_block
        end
        
        def handle_message(message)
            @db.process message.content
            Thread.new do
                sleep rand(REPLY_INTERVAL)
                @queue << nil unless @quiet
            end
        end
        
        def handle_quiet!(message)
            @quiet = true
        end
        
        def handle_unquiet!(message)
            @quiet = false
        end
    end
end