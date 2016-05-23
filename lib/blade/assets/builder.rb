class Blade::Assets::Builder
  attr_accessor :environment

  def initialize(environment)
    @environment = environment
  end

  def build
    clean
    compile
    install
  end

  private
    def compile
      environment.js_compressor = Blade.config.build.js_compressor.try(:to_sym)
      environment.css_compressor = Blade.config.build.css_compressor.try(:to_sym)
      manifest.compile(logical_paths)
    end

    def install
      create_dist_path

      logical_paths.each do |logical_path|
        fingerprint_path = manifest.assets[logical_path]
        FileUtils.cp(compile_path.join(fingerprint_path), dist_path.join(logical_path))
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

    def dist_path
      Pathname.new(Blade.config.build.path)
    end

    def compile_path
      Blade.tmp_path.join("compile")
    end
end
