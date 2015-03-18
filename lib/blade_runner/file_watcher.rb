require "listen"

class BladeRunner
  class FileWatcher < Base
    def start
      Listen.to(*runner.config.watch_files) do |modified, added, removed|
        publish("/filewatcher", modified: modified, added: added, removed: removed)
      end.start
    end
  end
end
