require_relative '../sam-build-fast'

module SamBuildFast
  class Command
    Options = Struct.new(
      :base_dir,
      :output_dir,
      :build_dir,
      :cache_dir,
      :template_file,
      :use_container,
      :skip_pull_image,
      :debug,
      :function_ids
    )

    class << self
      def run_cli(args)
        new(parse_cli(args)).build
      end

      private

      def parse_cli(args)
        require 'optparse'

        options = Options.new

        parser = OptionParser.new
        parser.on('-o DIRECTORY', '--output-dir') {|v| options.output_dir = v }
        parser.on('-s DIRECTORY', '--base-dir') {|v| options.base_dir = v }
        parser.on('--cache-dir DIRECTORY') {|v| options.cache_dir = v }
        parser.on('-t PATH', '--template', '--template-file') {|v| options.template_file = v }
        parser.on('-u', '--use-container') { options.use_container = true }
        parser.on('--skip-pull-imagee') { options.skip_pull_image = true }
        parser.on('--debug') { options.debug = true }

        positional = parser.parse(args)

        options.function_ids = positional unless positional.empty?

        options
      end
    end

    def initialize(options)
      @options = options

      options.template_file ||= find_template_file
      options.base_dir ||= File.expand_path('..', options.template_file)
      options.output_dir ||= File.expand_path('../.aws-sam', options.template_file)
      options.build_dir ||= File.join(options.output_dir, 'build')
      options.cache_dir ||= File.join(options.output_dir, 'cache')
    end

    attr_reader :options

    def build
      unless options.use_container
        $stderr.puts "Warning: Only --use-container is supported."
      end

      debug = options.debug

      if debug
        pp options
      end

      parser = File.open(options[:template_file], &TemplateParser.method(:new))
      template = parser.root.to_ruby

      if debug
        puts Psych.dump(template)
      end

      buidler = Builder.new(**options.to_h.slice(:base_dir, :build_dir, :cache_dir, :skip_pull_image))
      buidler.build(template, options.function_ids)
    end

    def clean
      require 'fileutils'
      FileUtils.rm_rf(options.build_dir)
    end

    private

    TEMPLATE_FILES = %w[template.yml template.yaml template.json]

    def find_template_file
      TEMPLATE_FILES.find {|fn| File.exist?(fn) } or fail "Could not locate template file in #{Dir.pwd}"
    end
  end
end
