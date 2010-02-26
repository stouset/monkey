require 'pathname'
require 'monkey/ext/modexcl/rbmodexcl'

module Monkey
  def self.see(klass, &block)
    mod     = Module.new(&block)
    methods = mod.instance_methods(false)
    
    methods.each do |method|
      register_patch(klass, method.to_sym, mod)
    end
  end
  
  def self.patch(object, method, force = false, &scope)
    if object.kind_of?(Class)
      _patch(object, object, method, force, &scope)
    else
      metaclass = (class << object; self; end)
      klass     = object.class
      
      _patch(metaclass, klass, method, force, &scope)
    end
  end
  
  private
  
  def self._patch(object, klass, method, force, &scope)
    error_defined(klass, method) if klass.method_defined?(method) unless force
    
    patch = patch_for(klass, method)
    scope ? scope_patch(object, patch, &scope) : apply_patch(object, patch)
  end
  
  def self.scope_patch(object, patch)
    apply_patch(object, patch)
    yield
  ensure
    remove_patch(object, patch)
  end
  
  def self.apply_patch(object, patch)
    object.send(:include, patch)
  end
  
  def self.remove_patch(object, patch)
    object.send(:uninclude, patch)
  end
  
  def self.register_patch(klass, method, mod)
    error_patched(klass, method) if patch_for(klass, method)
    
    self.patches[klass][method] = mod
  end
  
  def self.patch_for(klass, method)
    self.patches[klass][method]
  end
  
  def self.patches
    @patches ||= Hash.new {|h,k| h[k] = Hash.new }
  end
  
  def error_patched(klass, method)
    raise "#{klass}##{method} already has a monkeypatch"
  end
  
  def error_defined(klass, method)
    raise "#{klass}##{method} is already defined; pass `force = true` to use anyway"
  end
end
