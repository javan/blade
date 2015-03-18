class BladeRunner
  class Base
    extend Forwardable

    attr_reader :runner

    def_delegators "runner.client", :subscribe, :publish

    def initialize(runner)
      @runner = runner
    end
  end
end
