module Blade::Component
  def self.included(base)
    Blade.register_component(base)
  end
end
