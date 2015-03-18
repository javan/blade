class BladeRunner
  class TapStream
    extend Forwardable

    attr_reader :writer, :reader

    def_delegators :writer, :puts
    def_delegators :reader, :gets

    @@streams = {}

    def self.for(identifier)
      if @@streams[identifier]
        if @@streams[identifier].closed?
          @@streams[identifier] = self.new(identifier)
        else
          @@streams[identifier]
        end
      else
        @@streams[identifier] = self.new(identifier)
      end
    end

    def initialize(identifier)
      @identifier
      @reader, @writer = IO.pipe
    end

    def plan(total_tests)
      puts "1..#{total_tests}"
    end

    def comment(comment)
      puts "# #{comment}"
    end

    def pass(number, name)
      puts "ok #{number} #{name}"
    end

    def fail(number, name)
      puts "not ok #{number} #{name}"
    end

    def done
      writer.close
    end

    def close
      writer.close unless writer.closed?
      reader.close unless reader.closed?
      @@streams.delete(@identifier)
    end

    def closed?
      writer.closed? && reader.closed?
    end
  end
end
