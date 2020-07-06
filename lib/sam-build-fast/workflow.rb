require_relative 'workflows'

module SamBuildFast
  class Workflow
    RUBY_WORKFLOWS = {
      '.' => Workflows::RubyBundler,
    }
    NODEJS_WORKFLOWS = {
      'yarn.lock' => Workflows::NodeYarn,
      '.' => Workflows::NodeNpm,
    }

    WORKFLOWS = {
      'ruby2.5' => RUBY_WORKFLOWS,
      'ruby2.7' => RUBY_WORKFLOWS,
      'nodejs10.x' => NODEJS_WORKFLOWS,
      'nodejs12.x' => NODEJS_WORKFLOWS,
    }

    def self.get(runtime, source_dir)
      source_dir = Pathname(source_dir)

      WORKFLOWS[runtime]&.each do |fn, workflow|
        return workflow if source_dir.join(fn).exist?
      end

      fail "No workflow available for runtime #{runtime} and source directory #{source_dir}"
    end
  end
end
