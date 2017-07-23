module LockDiff
  module Gem
    class Package
      extend Forwardable

      def_delegators :@spec, :name, :revision, :version, :repository_url

      def initialize(spec)
        @spec = spec
      end

      def ref
        revision || git_tag
      end

      def version_str
        revision || version.to_s
      end

      def different?(other)
        revision != other.revision || version != other.version
      end

      def url
        @spec.repository_url || @spec.homepage_url
      end

      def repository
        Github::RepositoryNameDetector.new(@spec.repository_url).call
      end

      private

      def git_tag
        return unless version
        return @git_tag if defined? @git_tag
        @git_tag = Github::TagFinder.new(
          repository: repository,
          package_name: name,
          version: version
        ).call
      end

    end
  end
end
