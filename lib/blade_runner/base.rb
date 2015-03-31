class BladeRunner
  class Base
    extend Forwardable

    attr_reader :runner

    def_delegators "runner.client", :subscribe, :publish

    def initialize(runner)
      @runner = runner
    end

    def start
      raise NotImplementedError
    end

    def stop
      raise NotImplementedError
    end
  end
end
