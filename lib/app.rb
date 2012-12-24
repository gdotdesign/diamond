class App
  attr_reader :config
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
  def features_dir
    Dir.pwd+'/features'
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
    @config[:node_webkit][:window][:icon] = @config[:app][:icons][:"256"]
    @config[:node_webkit].to_json
  end

  def build(dir,exclude = /^$/)
    FileUtils.mkdir dir unless Dir.exists? dir
    File.open(dir+'/style.css', 'w+') do |f|
      f.write compile_sass
    end
    File.open(dir+'/index.html', 'w+') do |f|
      f.write compile_haml
    end
    File.open(dir+'/index.js', 'w+') do |f|
      f.write compile_coffee exclude
    end
    FileUtils.cp_r Dir.glob(assets_dir+"/*/"), dir
  end

  #---------
  def compile_coffee(exclude=/^$/)
    x ="window.ENV = '#{$env}'\nwindow.VERSION='#{@config[:app][:version]}'\n"
    builder = Builder.new exclude
    builder.build([source_dir+"/index.coffee"],x)
  end

  def compile_features
    r = ""
    Dir.glob(features_dir+"/**/*.feature").each do |file|
      r += File.read file
    end
    r
  end

  def compile_haml
    engine = Haml::Engine.new(File.read(views_dir+'/layout.haml'))
    engine.render(Scope.new(views_dir), {}, &Proc.new{
      Haml::Engine.new(File.read(views_dir+"/index.haml")).render(Scope.new(views_dir))
    })
  end

  def compile_sass
    cssengine = Sass::Engine.new(File.read(styles_dir+'/style.sass'),:load_paths => [styles_dir],:cache => false)
    cssengine.render()
  end

  def compile_specs
    code = ''
    FileList[specs_dir+"/support/*.coffee"].each do |f|
      code +=  File.read(f)+"\n"
    end
    FileList[specs_dir+"/**/*.coffee"].exclude(specs_dir+'/support/*.coffee').each do |f|
      code +=  File.read(f)+"\n"
    end
    CoffeeScript.compile code, bare: true
  end
  #---------

  def run_node_webkit
    build_node_webkit
    command = "nw #{nw_dir}"
    command += " --developer" unless $env == 'production'
    `#{command}`
    FileUtils.rm_r nw_dir
  end

  def build_node_webkit
    build nw_dir
    File.open(nw_dir+'/package.json', 'w+') do |f|
      f.write nw_manifest
    end
  end

  def build_chrome
    build build_dir, /\.nw\./
    File.open(build_dir+'/manifest.json', 'w+') do |f|
      f.write chrome_manifest
    end
  end


  #---------
  def linux32
    FileUtils.cp_r "#{$app.config[:node_webkit_directory]}/linux32", "packages"
    `cat packages/linux32/nw app.nw > packages/linux32/#{$app.config[:app][:name].downcase} && chmod +x packages/linux32/#{$app.config[:app][:name].downcase}`
    FileUtils.rm_r "packages/linux32/nw"
  end

  def linux64
    FileUtils.cp_r "#{$app.config[:node_webkit_directory]}/linux64", "packages"
    `cat packages/linux64/nw app.nw > packages/linux64/#{$app.config[:app][:name].downcase} && chmod +x packages/linux64/#{$app.config[:app][:name].downcase}`
    FileUtils.rm_r "packages/linux64/nw"
  end

  def win32
    FileUtils.cp_r "#{$app.config[:node_webkit_directory]}/win32", "packages"
    `cat packages/win32/nw.exe app.nw > packages/win32/#{$app.config[:app][:name].downcase}.exe`
    FileUtils.rm_r "packages/win32/nw.exe"
  end

  def mac32
    FileUtils.cp_r "#{$app.config[:node_webkit_directory]}/mac32", "packages"
    `cp app.nw packages/mac32/node-webkit.app/Contents/Resources/app.nw`
  end
end