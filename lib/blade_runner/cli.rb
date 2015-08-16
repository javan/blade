require "thor"

class BladeRunner::CLI < Thor
  desc "console", "Start in console mode"
  def console
    BladeRunner.start(interface: :console)
  end

  desc "ci", "Start in CI mode"
  def ci
    BladeRunner.start(interface: :ci)
  end
end
