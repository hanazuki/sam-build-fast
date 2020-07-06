require_relative 'template_parser'
require_relative 'builder'

require 'optparse'

module SamBuildFast
  class Cli
    def run(args)
      options = parse(args)

      unless options[:use_container]
        $stderr.puts "Warning: Only --use-container is supported."
      end

      options[:template_file] ||= find_template_file
      options[:base_dir] ||= File.expand_path('..', options[:template_file])
      options[:build_dir] ||= File.expand_path('../.aws-sam/build', options[:template_file])
      options[:cache_dir] ||= File.expand_path('../.aws-sam/cache', options[:template_file])

      debug = options[:debug]

      if debug
        pp options
      end

      parser = File.open(options[:template_file], &TemplateParser.method(:new))
      template = parser.root.to_ruby

      if debug
        puts Psych.dump(template)
      end

      buidler = Builder.new(**options.slice(:base_dir, :build_dir, :cache_dir))
      buidler.build(template, options[:function_ids])
    end

    private

    def parse(args)
      options = {}

      parser = OptionParser.new
      parser.on('-b DIRECTORY', '--build-dir') {|v| options[:build_dir] = v }
      parser.on('-s DIRECTORY', '--base-dir') {|v| options[:base_dir] = v }
      parser.on('--cache-dir DIRECTORY') {|v| options[:cache_dir] = v }
      parser.on('-t PATH', '--template', '--template-file') {|v| options[:template_file] = v }
      parser.on('-u', '--use-container') { options[:use_container] = true }
      parser.on('--skip-pull-imagee') { options[:skip_pull_image] = true }
      parser.on('--debug') { options[:debug] = true }

      positional = parser.parse(args)

      options[:function_ids] = positional unless positional.empty?

      options
    end

    TEMPLATE_FILES = %w[template.yml template.yaml template.json]

    def find_template_file
      TEMPLATE_FILES.find {|fn| File.exist?(fn) } or fail "Could not locate template file in #{Dir.pwd}"
    end
  end
end
