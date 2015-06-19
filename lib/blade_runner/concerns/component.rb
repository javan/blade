module BladeRunner::Component
  def self.included(base)
    BladeRunner.register_component(base)
  end
end
