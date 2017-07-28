require "fileutils"
require "ostruct"
require "webrick"
require "json"
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
    pages = Dir["[^_]*.mote"].map do |template|
      Hash.new.tap do |page|
        page[:id], page[:locale] = File.basename(template, ".mote").split(".")
        page[:path] = "%s.html" % page[:id]
        page[:destination] = "./%s/%s/%s" % [BUILD_DIR, page[:locale], page[:path]]
        frontmatter, page[:body] = File.read(template).match(FILE_REGEX)[1..2]
        page.merge!(YAML.load(frontmatter))
      end
    end
    site = OpenStruct.new(pages: JSON.parse(pages.to_json, object_class: OpenStruct))
    site.pages.map(&:locale).uniq.each {|dir|
      FileUtils.mkpath "./%s/%s" % [BUILD_DIR, dir] }
    site.pages.each do |page|
      File.open(page.destination, "w") do |file|
        file.write Context.new(site, page).render
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

    def initialize(site, page)
      if File.exist?(file = File.join(Dir.pwd, 'helper.rb'))
        require file
        extend Sew::Helper
      end

      @data = site
      @data.page = page
      @data.content = mote(page.body)
    end

    def render
      partial("_layout")
    end

    def mote(content)
      Mote.parse(content, self, data.each_pair.map(&:first))[data]
    end

    def partial(template)
      localized = sprintf("%s.%s.mote", template, @data.page.locale)
      if File.exist?(localized)
        mote(File.read(localized))
      else
        mote(File.read(sprintf("%s.mote", template)))
      end
    end
  end
end
