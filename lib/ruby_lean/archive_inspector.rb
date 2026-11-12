# frozen_string_literal: true

require "rubygems"
require "rubygems/package"
require "tmpdir"
require "open3"
require "zlib"

module RubyLean
  class ArchiveInspector
    ArchiveData = Struct.new(:archive_files, :file_count, :total_bytes, :largest_files, :build_warnings, keyword_init: true)

    def self.inspect_package(package)
      new.inspect_package(package)
    end

    def inspect_package(package)
      Dir.mktmpdir("ruby-lean-") do |tmpdir|
        output_gem = File.join(tmpdir, "#{package.name}-#{package.version}.gem")
        gemspec_filename = File.basename(package.gemspec_path)

        cmd = ["gem", "build", gemspec_filename, "--output", output_gem]
        stdout, stderr, status = Open3.capture3(*cmd, chdir: package.gem_root)

        unless status.success? && File.exist?(output_gem)
          error_msg = stderr.to_s.strip
          error_msg = stdout.to_s.strip if error_msg.empty?
          error_msg = "Unknown gem build error" if error_msg.empty?
          raise BuildError, error_msg
        end

        parse_archive(output_gem, stderr)
      end
    end

    private

    def parse_archive(gem_path, stderr)
      archive_files = []
      file_entries = []
      total_bytes = 0

      File.open(gem_path, "rb") do |io|
        Gem::Package::TarReader.new(io) do |reader|
          reader.each do |entry|
            next unless entry.full_name == "data.tar.gz"

            gz = Zlib::GzipReader.new(entry)
            Gem::Package::TarReader.new(gz) do |data_reader|
              data_reader.each do |data_entry|
                next unless data_entry.file?

                fname = data_entry.full_name
                fsize = data_entry.header.size

                archive_files << fname
                file_entries << { "path" => fname, "bytes" => fsize }
                total_bytes += fsize
              end
            end
          end
        end
      end

      largest_files = file_entries.sort_by { |e| -e["bytes"] }.first(5)

      ArchiveData.new(
        archive_files: archive_files.sort,
        file_count: archive_files.size,
        total_bytes: total_bytes,
        largest_files: largest_files,
        build_warnings: stderr.to_s.strip
      )
    end
  end
end
