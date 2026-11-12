# frozen_string_literal: true

require "optparse"

module RubyLean
  class CLI
    def self.start(args = ARGV)
      new.start(args)
    end

    def start(args = ARGV)
      options = {
        format: "text",
        strict: false,
        archive: true,
        quiet: false
      }

      args = args.dup

      # Check top-level flags first
      if args.include?("-v") || args.include?("--version")
        puts "ruby-lean #{RubyLean::VERSION}"
        return 0
      end

      # Extract command if provided
      command = "lint"
      if args.first == "lint"
        args.shift
      elsif args.first && !args.first.start_with?("-") && File.exist?(args.first)
        # First arg is a path
        options[:path] = args.shift
      end

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: ruby-lean lint [PATH] [options]"
        opts.separator ""
        opts.separator "Options:"

        opts.on("--gemspec PATH", "Path to explicit .gemspec file") do |path|
          options[:gemspec] = path
        end

        opts.on("-f", "--format FORMAT", %w[text json], "Output format (text, json; default: text)") do |fmt|
          options[:format] = fmt
        end

        opts.on("-s", "--strict", "Fail on warnings as well as errors") do
          options[:strict] = true
        end

        opts.on("--no-archive", "Inspect gemspec file list only without building archive") do
          options[:archive] = false
        end

        opts.on("-q", "--quiet", "Suppress non-essential informational output") do
          options[:quiet] = true
        end

        opts.on_tail("-v", "--version", "Print version and exit") do
          puts "ruby-lean #{RubyLean::VERSION}"
          return 0
        end

        opts.on_tail("-h", "--help", "Show this help message and exit") do
          puts opts
          return 0
        end
      end

      begin
        remaining = parser.parse!(args)
        options[:path] ||= remaining.first || "."
      rescue OptionParser::InvalidOption, OptionParser::InvalidArgument => e
        warn "Error: #{e.message}"
        warn "Run 'ruby-lean --help' for usage instructions."
        return 2
      end

      begin
        Command::Lint.run(options)
      rescue ExecutionError => e
        warn "Error: #{e.message}"
        2
      rescue StandardError => e
        warn "Unexpected error: #{e.message}"
        warn e.backtrace.join("\n") if $DEBUG
        2
      end
    end
  end
end
