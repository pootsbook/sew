require "fileutils"
require "ostruct"
require "webrick"
require "json"
require "mote"
require "yaml"

class Sew
  VERSION = "0.0.1"
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
        frontmatter, page[:body] = File.read(template).match(FILE_REGEX)[1..2]
        page.merge!(YAML.load(frontmatter))
        page[:path] = "%s.html" % (page["path"]&.tr(".", "/") || page[:id])
        page[:destination] = "./%s/%s/%s" % [BUILD_DIR, page[:locale], page[:path]]
        page[:destination_dir] = page[:destination].split("/")[0..-2].join("/") # build this up gradually using existing info
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

      @site= site
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
  end
end
