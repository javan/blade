module BladeRunner::Knife
  extend Forwardable

  def_delegators "BladeRunner", :config, :root_path, :tmp_path
  def_delegators "BladeRunner.client", :subscribe, :publish
end
