require 'sqlite3'
require 'unicode_utils/u'
require 'unicode_utils/nfkd'
require 'unicode_utils/downcase'

module Parrot
    # Calculates the average standard deviation of the elements of the given array.
    def self.avg_stddev(array)
        avg = array.reduce(:+) / array.size
        [avg, Math.sqrt(array.reduce(0) {|total, x| total + (x - avg) ** 2})]
    end
    
    # Returns a random number drawn from a normal distribution with the given average and standard deviation.
    def self.gaussian_rand(avg, stddev)
       t = 2 * Math::PI * rand
       scale = stddev * Math.sqrt(-2 * Math.log(1 - rand))
       avg + scale * Math.cos(t)
    end
    
    class Database
        BLOCK_LENGTH_WINDOW = 32
        DEFAULT_BLOCK_LENGTH = 16
        MIN_BLOCK_LENGTH = 1
        
        def initialize(filename)
            @db = SQLite3::Database.new filename, results_as_hash: true
            # Initialize tables if necessary
            @db.execute_batch '
                CREATE TABLE IF NOT EXISTS WordAssociations (
                    first TEXT NOT NULL,
                    second TEXT NOT NULL,
                    count INTEGER NOT NULL CHECK (count >= 0),
                    
                    PRIMARY KEY (first, second)
                );
                
                CREATE TABLE IF NOT EXISTS Words (
                    word TEXT PRIMARY KEY,
                    count INTEGER NOT NULL CHECK (count >= 0)
                );
                
                CREATE TABLE IF NOT EXISTS BlockLengths (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    length INTEGER NOT NULL CHECK (length >= 0)
                );
                
                CREATE INDEX IF NOT EXISTS Assoc_Index ON WordAssociations (first, count DESC);
            '
        end
        
        # Increments the number of times in the database that word2 has been seen following word1. This count is initialized to 1 if it is not registered yet.
        def see_words(word1, word2)
            @db.execute_batch "
                INSERT OR IGNORE INTO WordAssociations VALUES (?1, ?2, 0);
                UPDATE WordAssociations SET count = count + 1 WHERE first = ?1 AND second = ?2;
            ", [word1, word2]
            @db.execute_batch "
                INSERT OR IGNORE INTO Words VALUES (?1, 0);
                UPDATE Words SET count = count + 1 WHERE word = ?1
            ", [word1]
        end
        
        # Returns a random word, picking any of the already-seen words with equal probability. If no word has been seen yet, returns a suitable default.
        def random_word
            @db.get_first_value "SELECT word FROM Words WHERE rowid = abs(random())
            % (SELECT MAX(rowid) FROM Words) + 1" or
            "potato"
        end
        
        # Returns a random word, weighted by the frequencies of the words that have been seen following word and drawn from the set of these words.
        def random_word_after(word)
            if limit = @db.get_first_value("SELECT count FROM Words WHERE word = ?", word)
                pick = rand limit
                @db.execute "SELECT second, count FROM WordAssociations WHERE first = ? ORDER BY count DESC", word do |record|
                    pick -= record['count']
                    return record['second'] if pick < 0
                end
            else
                # If the word has not been seen before another word yet, just pick a random word
                return 
            end
        end
        
        # Normalizes the case and combining mark representations of the given word, returning the result. 
        def normalize_word(word)
            U.downcase(U.nfkd(word))
        end
        
        # Reads a block of text, records all words found in it and its length.
        def process(block)
            words = block.split(/\s*\b\s*/)
            # Record this block's length
            @db.execute "INSERT INTO BlockLengths (length) VALUES (?)", words.length
            @db.execute "DELETE FROM BlockLengths WHERE id <= (SELECT MAX(id) FROM BlockLengths) - #{BLOCK_LENGTH_WINDOW}"
            words.each_cons(2) {|word1, word2| see_words normalize_word(word1), normalize_word(word2)}
        end
        
        # Returns the length of the next block to be generated.
        def length_next_block
            lengths = @db.execute("SELECT length FROM BlockLengths").map! {|record| record['length']}
            return DEFAULT_BLOCK_LENGTH if lengths.empty?
            [Parrot.gaussian_rand(*Parrot.avg_stddev(lengths)), MIN_BLOCK_LENGTH].max.floor
        end
        
        # Returns a block of text with a random number of words, based on the average of the last few blocks processed. The resulting block will always be at least one word long.
        def gen_block
            last_word = random_word
            text = last_word.dup
            (length_next_block - 1).times do
                word = random_word_after last_word
                # Do not add spaces before punctation
                text << " " if word !~ /[[:punct:]]/
                text << word
                last_word = word
            end
            text
        end
        
        # Closes the underlying database handle.
        def close
            @db.close
        end
    end
end