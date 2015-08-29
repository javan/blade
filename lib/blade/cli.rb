require "thor"

class Blade::CLI < Thor
  desc "runner", "Start test runner in console mode"
  def runner
    Blade.start(interface: :runner)
  end

  desc "ci", "Start test runner in CI mode"
  def ci
    Blade.start(interface: :ci)
  end
end
