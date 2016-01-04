module Blade::RackRouter
  extend ActiveSupport::Concern

  DEFAULT = :*

  included do
    cattr_accessor(:routes) { Hash.new }
  end

  class_methods do
    def route(path, action)
      pattern = /^\/?#{path.gsub(/\*/, ".*")}$/
      base_path = path.match(/([^\*]*)\*?/)[1]
      routes[path] = { action: action, pattern: pattern, base_path: base_path }
      self.routes = routes.sort_by { |path, value| -path.size }.to_h
      routes[path]
    end

    def default_route(action)
      routes[DEFAULT] = { action: action }
    end

    def find_route(path)
      if route = routes.detect { |key, details| path =~ details[:pattern] }
        route[1]
      else
        routes[DEFAULT]
      end
    end
  end

  private
    def find_route(*args)
      self.class.find_route(*args)
    end
end
