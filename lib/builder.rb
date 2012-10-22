class Builder
  attr_reader :files

  def initialize(excludePatter = /^$/)
    @files = []
    @excludePatter = excludePatter
  end

  def build(files = [], content = "", ugly = false)
    files.each do |f|
       add f unless f =~ @excludePatter
    end
    @content = content
    assemble
    compile
    if !!ENV['ugly']
      uglify
    else
      @compiled
    end
  end

  def add(path)
    if File.file?(path)
      #exact path
      realpath = Pathname.new(path).realpath
      basePath = Pathname.new(File.dirname(realpath))
      contents = File.read(path)
      m = contents.scan /@requires\s(.*)[\n|\r\$]/
      m.each do |dependency|
        p = basePath+dependency[0]
        add p unless @files.include? p
      end
      @files.push realpath unless @files.include? realpath
    elsif File.directory?(path)
      #directory
      Dir.glob(path.to_s+"/*.coffee").each do |f|
        add f unless @files.include? f
      end
    elsif File.file?(path.to_s+".coffee")
      path.to_s+".coffee"
      #without extension
    end
  end

  def assemble
    @contents = @content
    @files.each do |path|
      if File.exists?(path)
        @contents += "\n###\n--------------- #{path}--------------\n###\n"
        content = File.read(path)
        if content =~ /@docs/
          @contents += content.split(/#\s@docs[\n|\r\$]/)[0]+"\n"
        else
          @contents += content
        end
      end
    end
    @contents
  end

  def compile
    @compiled = CoffeeScript.compile @contents, bare: true
  end

  def uglify
    @uglified = Uglifier.compile(@compiled)
  end

end