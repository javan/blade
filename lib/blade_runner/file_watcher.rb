require "listen"

class BladeRunner::FileWatcher
  include BladeRunner::Knife

  def start
    @listener = Listen.to(*config.watch_files) do |modified, added, removed|
      publish("/filewatcher", modified: modified, added: added, removed: removed)
    end
    @listener.start
  end

  def stop
    @listener.stop
  end
end
