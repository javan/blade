module BladeRunner::Knife
  extend Forwardable

  def_delegators "BladeRunner", :config, :assets, :server, :sessions, :blade_url, :root_path, :tmp_path
  def_delegators "BladeRunner.client", :subscribe, :publish
end
