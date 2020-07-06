require 'pathname'
require 'shellwords'

module SamBuildFast
  module Workflows
    class Base
      def initialize(source_dir:, build_dir:, cache_dir:)
        @source_dir = Pathname(source_dir)
        @build_dir = Pathname(build_dir)
        @cache_dir = Pathname(cache_dir)
      end

      attr_reader :source_dir, :build_dir, :cache_dir

      DEFAULT_NO_COPY = %w[.git .aws-sam]

      def copy_files?
        self.class.const_get(:DO_COPY)
      end

      def no_copy_files
        self.class.const_get(:NO_COPY)
      end

      def build_env
        {}
      end

      def build_command
        fail "#{self.class}#build_command is not implemented."
      end

      private

      def shellescape(s)
        s.to_s.shellescape
      end
    end

    class RubyBundler < Base
      DO_COPY = true
      NO_COPY = %w[vendor/bundle]

      def build_env
        {
          BUNDLE_DEPLOYMENT: true,
          BUNDLE_CLEAN: true,
          BUNDLE_PATH: 'vendor/bundle',
          BUNDLE_GLOBAL_GEM_CACHE: true,
          BUNDLE_USER_CACHE: cache_dir + 'bundler',
        }
      end

      def build_command
        <<EOF
cd #{shellescape(build_dir)}
bundle install
EOF
      end
    end

    class NodeNpm < Base
      DO_COPY = true
      NO_COPY = %w[node_modules]

      def build_env
        {
          npm_config_cache: cache_dir + 'npm',
        }
      end

      def build_command
        <<EOF
cd #{shellescape(build_dir)}
npm install --no-audit
EOF
      end
    end

    class NodeYarn < NodeNpm
      def build_env
        super.merge(
          YARN_CACHE_FOLDER: cache_dir + 'yarn',
        )
      end

      def build_command
        <<EOF
npm -g install yarn

cd #{shellescape(build_dir)}
yarn install
EOF
      end
    end
  end
end
