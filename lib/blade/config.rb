class Blade::Config < ActiveSupport::HashWithIndifferentAccess
  def method_missing(method, *args)
    case method
    when /=$/
      self[$`] = args.first
    when /\?$/
      self[$`].present?
    else
      if self[method].is_a?(Hash) && !self[method].is_a?(self.class)
        self[method] = self.class.new(self[method])
      end
      self[method]
    end
  end
end
