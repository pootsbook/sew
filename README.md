Sew
===

Static, Elegant Websites; stitched together.

Description
-----------

Sew is a simple static site generator.

## Motivation

A rejection of [Jekyll](https://jekyllrb.com) and [Middleman](https://middlemanapp.com) for simpler sites.

## Inspiration

Inspired by @soveran’s [Mote](https://github.com/soveran/mote), a simple and fast template engine.

Documentation
-------------

Sew is built around the following data structures:

### Site

A *Site* is a struct/dictionary/hash containing an array of *Pages* and *Data* files.  
```
site = {
  pages: [page…]
  data: [data…]
}
```

### Page

A *Page* is a struct/dictionary/hash describing the attributes of a single page. This is a combination of:

- `id`, lifted from the filename
- `locale`, lifted from the filename
- `body`, lifted from the file contents
- _Additional attributes_ are read from the YAML front matter, e.g. `title`
- `path`, lifted from the file path
- `destination_dir` computed from `BUILD_DIR`, `locale`, `path`
- `destination` computed from `destination_dir` + name of HTML file

The page `index.en.html` in the project root with the following contents:

```
---
title: "Home Page"
---
<p>Welcome to my site.</p>
```

would be represented thus:

```
page = {
  id: "index",
  locale: :en,
  body: "<p>Welcome to my site</p>",
  title: "Home Page",
  path: "/",
  destination_dir: "/build/en/",
  destination: "/build/en/index.html"
}
```

### Data

A *Data* file is the Ruby representation of the contents of any YAML file placed in the project root. The key is generated from the filename.

Example
-------

Sew is designed to be used with only one directory.

```
_layout.mote                # layout
_header.mote                # partial
articles.yml                # data file, accessible via 'data.articles'
index.en.html               # /en/index.html
index.nl.html               # /nl/index.html
portfolio.logo-work.en.html # /en/portfolio/logo-work/index.html
```

Page attributes are accessible via the `page` object, e.g. `page.title`.

```
<!-- _layout.mote -->
<html lang="{{page.locale}}">
  <head>
  <meta charset="utf-8">
    <title>{{page.title}}</title>
    {{ partial("_header") }}
  </head>
  <body>
    <div class="container">
      {{content}}
    </div>

    <ul>
% data.articles.each do |article|
  <li>{{article.title}}</li>
% end
    </ul>
  </body>
</html>
```
