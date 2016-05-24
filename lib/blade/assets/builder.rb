class Blade::Assets::Builder
  attr_accessor :environment

  def initialize(environment)
    @environment = environment
  end

  def build
    puts "Building assets…"

    clean
    compile
    clean_dist_path
    create_dist_path
    install
  end

  private
    def compile
      environment.js_compressor = Blade.config.build.js_compressor.try(:to_sym)
      environment.css_compressor = Blade.config.build.css_compressor.try(:to_sym)
      manifest.compile(logical_paths)
    end

    def install
      logical_paths.each do |logical_path|
        fingerprint_path = manifest.assets[logical_path]
        source_path = compile_path.join(fingerprint_path)
        destination_path = dist_path.join(logical_path)
        FileUtils.cp(source_path, destination_path)
        puts "[created] #{destination_path}"
      end
    end

    def manifest
      @manifest ||= Sprockets::Manifest.new(environment.index, compile_path)
    end

    def clean
      compile_path.rmtree if compile_path.exist?
      compile_path.mkpath
    end

    def logical_paths
      Blade.config.build.logical_paths
    end

    def create_dist_path
      dist_path.mkpath unless dist_path.exist?
    end

    def clean_dist_path
      if clean_dist_path?
        children = dist_path.children
        dist_path.rmtree
        children.each do |child|
          puts "[removed] #{child}"
        end
      end
    end

    def clean_dist_path?
      Blade.config.build.clean && dist_path.exist?
    end

    def dist_path
      @dist_path ||= Pathname.new(Blade.config.build.path)
    end

    def compile_path
      @compile_path ||= Blade.tmp_path.join("compile")
    end
end
