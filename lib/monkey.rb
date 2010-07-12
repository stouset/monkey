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
  # Patches +object+ to contain the monkeypatched +methods+. If a block is
  # passed, the monkeypatches are only active for the duration of the block, 
  # and the return value is the return value of the block.
  #
  # Raises a Monkey::MethodMissingError if a named monkeypatch is not defined.
  #
  #   Monkey.patch(Object, :metaclass) do
  #     "foo".metaclass # => #<Class:#<String:0x10153caf8>>
  #   end
  #
  #   "foo".metaclass # => NoMethodError
  #
  def self.patch(object, *methods, &scope)
    # if the object is a class or metaclass, monkeypatch the class, otherwise
    # monkeypatch the metaclass of the object
    if object.kind_of?(Class)
      _patch(object, object, *methods, &scope)
    else
      metaclass = (class << object; self; end)
      klass     = object.class
      
      _patch(metaclass, klass, *methods, &scope)
    end
  end
  
  private
  
  #
  # Actually applies monkeypatches to +object+. Looks up the +methods+ to be
  # patched in the scope of of +klass+.
  #
  def self._patch(object, klass, *methods, &scope)
    patches = methods.map do |method|
      patch = klass.ancestors.map {|a| patch_for(a, method) }.compact.first
      error_missing(klass, method) if patch.nil?
      patch
    end
    
    scope ? scope_patches(object, *patches, &scope) \
          : apply_patches(object, *patches)
  end
  
  #
  # Applies +patches+ to +object+, yields, then removes the patches when the
  # block returns.
  #
  def self.scope_patches(object, *patches)
    apply_patches(object, *patches)
    yield
  ensure
    remove_patches(object, *patches)
  end
  
  #
  # Applies the Modules +patches+ to +object+.
  #
  def self.apply_patches(object, *patches)
    patches.each {|patch| object.send(:include, patch) }
  end
  
  #
  # Removes the Modules +patches+ from +object+.
  #
  def self.remove_patches(object, *patches)
    patches.each {|patch| object.send(:uninclude, patch) }
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
