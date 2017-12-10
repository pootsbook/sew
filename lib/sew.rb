require "fileutils"
require "ostruct"
require "webrick"
require "json"
require "mote"
require "yaml"

class Sew
  VERSION = "0.0.4"
  BUILD_DIR = ENV["SITE_DIR"] || "build"
  FILE_REGEX = /\A---\n(.+?)\n---\n(.*)/m
  PATH_MAP = Hash.new do |hash, key|
    key == "index" ? "/" : "/%s/" % key.tr(".", "/")
  end

  def self.version
    puts VERSION
  end

  def self.build
    clean
    pages = Dir["[^_]*.mote"].map do |template|
      Hash.new.tap do |page|
        parts = File.basename(template, ".mote").split(".")
        page[:locale] = parts.pop.intern
        page[:id] = parts.join(".")
        frontmatter, page[:body] = File.read(template).match(FILE_REGEX)[1..2]
        page.merge!(YAML.load(frontmatter))
        page[:path] = PATH_MAP[(page.delete("path") || page[:id])]
        page[:destination_dir] = ("./%s/%s" % [BUILD_DIR, page[:locale]]) + page[:path]
        page[:destination] = page[:destination_dir] + "index.html"
      end
    end
    data = Hash.new.tap do |dat|
      Dir["*.yml"].map do |file|
        dat[File.basename(file, ".yml")] = YAML.load_file(file)
      end
    end
    site = OpenStruct.new(JSON.parse({ pages: pages, data: data }.to_json, object_class: OpenStruct))
    context = Context.new(site)
    site.pages.map(&:destination_dir).uniq.each(&FileUtils.method(:mkpath))
    site.pages.each do |page|
      File.open(page.destination, "w") do |file|
        file.write context.render(page)
      end
    end
    context.after_build
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
    attr_reader :site

    def initialize(site)
      if File.exist?(file = File.join(Dir.pwd, 'helper.rb'))
        require file
        extend Sew::Helper
      end

      @site = site
    end

    def render(page)
      @site.page = page
      @site.content = mote(page.body)

      partial("_layout")
    end

    def mote(content)
      Mote.parse(content, self, site.each_pair.map(&:first))[site]
    end

    def partial(template)
      localized = sprintf("%s.%s.mote", template, site.page.locale)
      if File.exist?(localized)
        mote(File.read(localized))
      else
        mote(File.read(sprintf("%s.mote", template)))
      end
    end

    def after_build
    end
  end
end
