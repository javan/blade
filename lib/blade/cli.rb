require "thor"

class Blade::CLI < Thor
  desc "console", "Start in console mode"
  def console
    Blade.start(interface: :console)
  end

  desc "ci", "Start in CI mode"
  def ci
    Blade.start(interface: :ci)
  end
end
