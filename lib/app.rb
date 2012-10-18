class App
  def load_config
    @config = YAML::load_file(Dir.pwd+"/diamond.yml").symbolize_keys!
  end

  #---------
  def source_dir
    Dir.pwd+"/"+@config[:directories][:source]
  end
  def views_dir
    Dir.pwd+"/"+@config[:directories][:views]
  end
  def styles_dir
    Dir.pwd+"/"+@config[:directories][:stylesheets]
  end
  def assets_dir
    Dir.pwd+"/"+@config[:directories][:assets]
  end
  def specs_dir
    Dir.pwd+"/"+@config[:directories][:specs]
  end
  def build_dir
    Dir.pwd+'/.build'
  end
  def nw_dir
    Dir.pwd+'/.nw_build'
  end
  #---------

  def chrome_manifest
    @config[:chrome].merge(@config[:app]).to_json
  end

  def nw_manifest
    @config[:node_webkit].to_json
  end

  def build(dir)
    FileUtils.mkdir dir unless Dir.exists? dir
    File.open(dir+'/style.css', 'w+') do |f|
      f.write compile_sass
    end
    File.open(dir+'/index.html', 'w+') do |f|
      f.write compile_haml
    end
    File.open(dir+'/index.js', 'w+') do |f|
      f.write compile_coffee
    end
    FileUtils.cp_r Dir.glob(assets_dir+"/*/"), dir
  end

  #---------
  def compile_coffee
    builder = Builder.new
    builder.build(Dir.glob(source_dir+"/**/*.coffee"))
  end

  def compile_haml
    engine = Haml::Engine.new(File.read(views_dir+'/layout.haml'))
    engine.render(Scope.new(views_dir), {}, &Proc.new{
      Haml::Engine.new(File.read(views_dir+"/index.haml")).render(Scope.new(views_dir))
    })
  end

  def compile_sass
    cssengine = Sass::Engine.new(File.read(styles_dir+'/style.sass'),:load_paths => [styles_dir])
    cssengine.render()
  end
  #---------

  def build_node_webkit
    build nw_dir
    File.open(nw_dir+'/package.json', 'w+') do |f|
      f.write nw_manifest
    end
    command = "nw #{nw_dir}"
    command += " --developer" unless $env == 'production'
    `#{command}`
    FileUtils.rm_r nw_dir
  end

end