module BladeRunner
  module Knife
    extend Forwardable

    def_delegators "BladeRunner", :config, :browsers, :root_path, :tmp_path
    def_delegators "BladeRunner.client", :subscribe, :publish
  end
end
