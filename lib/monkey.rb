require 'pathname'
require 'monkey/ext/modexcl/rbmodexcl'

module Monkey
  class MonkeyError        < StandardError; end
  class MethodPatchedError < MonkeyError;   end
  class MethodMissingError < MonkeyError;   end
  
  #
  # Allows you to specify a set of monkey patches that can be applied to a
  # class or module. Pass a block to the method and define methods inside the
  # block as normal, and the methods will be available only inside a
  # Monkey#patch block.
  #
  # Raises a Monkey::MethodPatchedError if the +method+ already has a
  # monkeypatch registered on +klass+.
  #
  #   Monkey.see(Object) do
  #     def metaclass
  #       (class << self; self; end)
  #     end
  #   end
  #
  def self.see(klass, &block)
    mod     = Module.new(&block)
    methods = mod.instance_methods(false)
    
    methods.each do |method|
      register_patch(klass, method.to_sym, mod)
    end
  end
  
  #
  # Patches +object+ to contain the monkeypatched +method+. If a block is
  # passed, the monkeypatch is only # active for the duration of the block, 
  # and the return value is the return # value of the block.
  #
  # Raises a Monkey::MethodMissingError if no such monkeypatch is defined.
  #
  #   Monkey.patch(Object, :metaclass) do
  #     "foo".metaclass # => #<Class:#<String:0x10153caf8>>
  #   end
  #
  #   "foo".metaclass # => NoMethodError
  #
  def self.patch(object, method, &scope)
    # if the object is a class or metaclass, monkeypatch the class, otherwise
    # monkeypatch the metaclass of the object
    if object.kind_of?(Class)
      _patch(object, object, method, &scope)
    else
      metaclass = (class << object; self; end)
      klass     = object.class
      
      _patch(metaclass, klass, method, &scope)
    end
  end
  
  private
  
  #
  # Actually applies a monkeypatch to +object+. Looks up the +method+ to be
  # patched in the scope of of +klass+.
  #
  def self._patch(object, klass, method, &scope)
    patch = patch_for(klass, method)
    
    error_missing(klass, method) if patch.nil?
    
    scope ? scope_patch(object, patch, &scope) : apply_patch(object, patch)
  end
  
  #
  # Applies +patch+ to +object+, yields, then removes the patch when the block
  # returns.
  #
  def self.scope_patch(object, patch)
    apply_patch(object, patch)
    yield
  ensure
    remove_patch(object, patch)
  end
  
  #
  # Applies the Module +patch+ to +object+.
  #
  def self.apply_patch(object, patch)
    object.send(:include, patch)
  end
  
  #
  # Removes the module +patch+ from +object+.
  #
  def self.remove_patch(object, patch)
    object.send(:uninclude, patch)
  end
  
  #
  # Registers a monkeypatch +patch+, which should be a module that defines the
  # named +method+. The patch is scoped to +klass+ and is named +method+.
  #
  def self.register_patch(klass, method, patch)
    error_patched(klass, method) if patch_for(klass, method)
    
    self.patches[klass][method] = patch
  end
  
  #
  # Looks up the monkeypatch for +method+ in +klass+.
  #
  def self.patch_for(klass, method)
    self.patches[klass][method]
  end
  
  #
  # A nested hash of existing monkeypatch definitions, first by class, then
  # method name.
  #
  def self.patches
    @patches ||= Hash.new {|h,k| h[k] = Hash.new }
  end
  
  def self.error_patched(klass, method)
    raise MethodPatchedError,
      "#{klass}##{method} already has a monkeypatch"
  end
  
  def self.error_missing(klass, method)
    raise MethodMissingError,
      "No monkeypatch #{klass}##{method} has been defined"
  end
end
