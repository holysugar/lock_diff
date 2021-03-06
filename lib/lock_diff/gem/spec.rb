module LockDiff
  module Gem
    # wrapper of lazy_specification
    module Spec
      class UnSupportSource < StandardError; end

      class << self
        def new(lazy_specification)
          case lazy_specification.source
          when Bundler::Source::Rubygems
            RubyGemSpec.new(lazy_specification)
          when Bundler::Source::Git
            GitSpec.new(lazy_specification)
          when Bundler::Source::Path
            PathSpec.new(lazy_specification)
          else
            raise UnSupportSource, "#{lazy_specification.source.class} source by #{lazy_specification.name} is not supported"
          end
        end

        def parse(lockfile)
          Bundler::LockfileParser.new(lockfile).specs.map do |lazy_specification|
            new(lazy_specification)
          end
        end

      end

      class Base
        extend Forwardable

        def_delegators :@spec, :name, :version

        def initialize(lazy_specification)
          @spec = lazy_specification
        end

        def revision
          @spec.git_version&.strip
        end

        def to_package
          Package.new(self)
        end

        def repository_url; end
        def ruby_gem_url; end
      end

      class RubyGemSpec < Base
        def_delegators :ruby_gem, :repository_url
        def_delegator :ruby_gem, :url, :ruby_gem_url

        private

        def ruby_gem
          @ruby_gem ||= RubyGem.new(@spec.name)
        end
      end

      class GitSpec < Base
        def repository_url
          @repository_url ||= Github::UrlDetector.new(@spec.source.uri).call
        end
      end

      class PathSpec < Base
      end
    end

    class NullSpec
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def revision
      end

      def version
        nil
      end

      def repository_url; end
      def ruby_gem_url; end

      def to_package
        Package.new(self)
      end
    end

  end
end
