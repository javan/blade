require "listen"

module BladeRunner
  class FileWatcher < Base
    def start
      @listener = Listen.to(*runner.config.watch_files) do |modified, added, removed|
        publish("/filewatcher", modified: modified, added: added, removed: removed)
      end
      @listener.start
    end

    def stop
      @listener.stop
    end
  end
end
