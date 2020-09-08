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

      def copy_destination_path
        "."
      end

      def build_env
        {}
      end

      def build_command
        fail "#{self.class}#build_command is not implemented."
      end

      def artifact_path
        '.'
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
          BUNDLE_JOBS: 2,
        }
      end

      def build_command
        <<EOF
cd #{shellescape(build_dir)}
GNUMAKEFLAGS="-j$(nproc)" bundle install
EOF
      end
    end

    # Not tested
    class NodeNpm < Base
      DO_COPY = true
      NO_COPY = %w[node_modules]

      def copy_destination_path
        'packaging'
      end

      def artifact_path
        'artifact'
      end

      def build_env
        {
          npm_config_cache: cache_dir + 'npm',
        }
      end

      def build_command
        <<EOF
cd #{shellescape(build_dir)}
rm -rf tmp artifact.old
mv -f artifact artifact.old
mkdir -p tmp artifact

pushd tmp
npm pack ../packaging
popd

pushd artifact
tar vxf ../tmp/*.tgz --strip-components=1
if test -d ../artifact.old/node_modules; then
  mv -f ../artifact.old/node_modules .
fi
npm install --no-audit --production
EOF
      end
    end

    # Not tested
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
