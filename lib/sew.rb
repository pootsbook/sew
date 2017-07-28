require "fileutils"
require "webrick"
require "mote"
require "yaml"

class Sew
  VERSION = "0.0.0"
  BUILD_DIR = "build"
  FILE_REGEX = /\A---\n(.+?)\n---\n(.*)/m

  def self.version
    puts VERSION
  end

  def self.build
    clean
    Dir.mkdir(BUILD_DIR)
    Dir["[^_]*.mote"].each do |template|
      filename = "./%s/%s.html" % [BUILD_DIR, File.basename(template, ".mote")]
      File.open(filename, "w") do |file|
        file.write Context.new(*File.read(template).match(FILE_REGEX)[1..2]).render
      end
    end
  end

  def self.clean
    FileUtils.rm_rf(BUILD_DIR)
  end

  def self.serve
    build
    root = File.expand_path(BUILD_DIR)
    server = WEBrick::HTTPServer.new(:Port => 4567, :DocumentRoot => root)
    trap('INT') { server.shutdown }
    server.start
  end

  class Context
    attr_reader :data

    def initialize(frontmatter, content)
      @data = YAML.load(frontmatter)
      @data.merge!(content: mote(content))
    end

    def render
      partial("_layout")
    end

    def mote(content)
      Mote.parse(content, self, data.keys)[data]
    end

    def partial(template)
      mote(File.read(sprintf("%s.mote", template)))
    end
  end
end
