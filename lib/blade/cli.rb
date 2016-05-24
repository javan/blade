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

  desc "build", "Build assets"
  def build
    Blade.build
  end

  desc "config", "Inspect Blade.config"
  def config
    require "pp"
    Blade.initialize!
    pp Blade.config
  end
end
