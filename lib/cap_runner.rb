require 'fileutils'

module CapRunner
  OUTSTREAM_PATH = File.expand_path('../../out/capistrano_fifo', __FILE__)
  PID_PATH = File.expand_path('../../out/pid', __FILE__)
  CAPISTRANO_DIR = File.expand_path('../../capistrano', __FILE__)
  class << self

    def started?
      File.exists?(PID_PATH)
    end

    def finish!
      FileUtils.rm_rf(PID_PATH)
    end

    def stream_output
      `mkfifo #{OUTSTREAM_PATH}` unless File.exist?(OUTSTREAM_PATH)
      open(OUTSTREAM_PATH, 'r+') do |file|
        while line = file.gets
          break if line == "\x00\n"
          yield line
        end
      end
    end

    def deploy(stream = write_outstream)
      Dir.chdir(CAPISTRANO_DIR)
      exec_command "cap -l STDOUT deploy", stream
    end

    def install(stream = write_outstream)
      Dir.chdir(CAPISTRANO_DIR)
      exec_command "cap -l STDOUT deploy:install", stream
    end

    def setup(stream = write_outstream)
      Dir.chdir(CAPISTRANO_DIR)
      exec_command "cap -l STDOUT deploy:setup", stream
    end

    private

    def exec_command(cmd, stream)
      start!
      IO.popen(cmd, 'r') do |data|
        while line = data.gets
          stream << line
          stream.flush if stream.respond_to? :flush
        end
      end
      stream.close if stream.respond_to? :close
      finish!
    end

    def write_outstream
      fifo_path = OUTSTREAM_PATH
      `rm #{fifo_path}`
      `mkfifo #{fifo_path}`
      outstream = open(fifo_path, 'w+')
      def outstream.close
        self.puts "\x00"
        self.flush
      end
      outstream
    end

    def start!
      FileUtils.touch(PID_PATH)
    end
  end
end