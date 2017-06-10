module BundleDiffLinker
  class GemfileLockComparator
    def self.by(pull_request)
      gemfile_lock = BundleDiffLinker::Github::GemfileLock.new(pull_request)
      new(old_ver: gemfile_lock.old_ver, new_ver: gemfile_lock.new_ver)
    end

    def initialize(old_ver:, new_ver:)
      @old_ver = old_ver
      @new_ver = new_ver
    end

    def compare
      old_specs_by_name = Bundler::LockfileParser.new(@old_ver).specs.group_by(&:name)
      Bundler::LockfileParser.new(@new_ver).specs.map do |new_spec|
        old_spec = old_specs_by_name[new_spec.name]&.first
        next unless old_spec

        GemDiff.new(old_gem: GemInfo.new(new_spec), new_gem: GemInfo.new(old_spec))
      end.compact.select(&:difference?)
    end

  end
end
