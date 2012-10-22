class Hash
  def symbolize_keys!
    t=self.dup
    self.clear
    t.each_pair do |k,v|
      if v.kind_of?(Hash)
        v.symbolize_keys!
      end
      self[k.to_s.to_sym] = v
      self
    end
    self
  end
end

def silence_stream(stream)
  old_stream = stream.dup
  stream.reopen('/dev/null')
  stream.sync = true
  yield
ensure
  stream.reopen(old_stream)
end

class Scope
  def initialize(base)
    @base = base
  end
  def haml(view,locals = {locals: {}}, &block)
    Haml::Engine.new(File.read(@base+"/"+view+".haml")).render Scope.new(@base), locals[:locals] do
      if defined? block
        capture_haml &block
      else
        ""
      end
    end
  end
end