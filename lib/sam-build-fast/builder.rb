require 'ostruct'
require 'pathname'
require 'digest/sha2'
require 'yaml'

module SamBuildFast
  class Function < OpenStruct
    def initialize(*)
      super

      unless self.code_uri.directory?
        fail "TODO"
      end

      self.workflow = Workflow.get(runtime, code_uri).new(
        source_dir: '/sam-build/source',
        build_dir: '/sam-build/build',
        cache_dir: '/sam-build/cache',
      )

      seeds = [runtime, code_uri]
      self.code_id = Digest::SHA256.hexdigest(seeds.map(&:to_s).join(?\0))

      self.artifact_path = "#{code_id}/#{workflow.artifact_path}"
    end

  end

  class Builder
    def initialize(base_dir:, build_dir:, cache_dir:, skip_pull_image: false)
      @base_dir = Pathname(base_dir)
      @build_dir = Pathname(build_dir)
      @cache_dir = Pathname(cache_dir)
      @skip_pull_image = skip_pull_image

      @pulled_images = {}
    end

    def build(template, function_ids)
      functions = extract_functions(template)

      jobs_done = {}
      functions.each do |id, function|
        if function_ids
          next unless function_ids.include?(id)
        end

        puts ">> Building function `#{id}'"

        if prev_job = jobs_done[function.code_id]
          puts "Reusing function `#{prev_job}'"
          next
        end

        build_function(id, function)

        jobs_done[function.code_id] = id
      end

      File.open(@build_dir + 'template.yaml', 'w') do |f|
        YAML.dump(template, f)
      end
    end

    private

    def extract_functions(template)
      resources = template.fetch('Resources')

      resources.each_with_object({}) do |(id, params), functions|
        type = params.fetch('Type')
        next unless props = params['Properties']

        case type
        when 'AWS::Serverless::Function'
          fun = functions[id] = Function.new(
            code_uri: @base_dir.join(props.fetch('CodeUri')).realpath,
            runtime: props.fetch('Runtime'),
            handler: props.fetch('Handler'),
          )
          props['CodeUri'] = fun.artifact_path
        end
      end
    end

    def build_function(id, function)
      job_build_dir = @build_dir.join(function.code_id).tap(&:mkpath)
      job_source_dir = function.code_uri

      workflow = function.workflow

      if workflow.copy_files?
        rsync_opts = %w[-a --delete]
        workflow.no_copy_files.each do |path|
          rsync_opts.push('--exclude', path)
        end

        copy_destination = job_build_dir.join(workflow.copy_destination_path).tap(&:mkpath)
        system(*['rsync', *rsync_opts, "#{job_source_dir}/", "#{copy_destination}/"], exception: true)
      end

      docker_image = "amazon/aws-sam-cli-build-image-#{function.runtime}"
      docker_run_opts =
        %W[
           --rm
           -v #{job_source_dir}:/sam-build/source:cached,ro
           -v #{job_build_dir}:/sam-build/build:delegated
           -v #{@cache_dir}:/sam-build/cache:delegated
          ]

      workflow.build_env.each do |k, v|
        docker_run_opts.push('-e', "#{k}=#{v}")
      end

      unless @skip_pull_image && !@pulled_images[docker_image]
        system(*['docker', 'pull', docker_image], exception: true)
        @pulled_images[docker_image] = true
      end

      system(*['docker', 'run', *docker_run_opts, docker_image, '/bin/bash', '-euxc', workflow.build_command], exception: true)
    end
  end
end
