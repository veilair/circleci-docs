#!/usr/bin/env ruby

require 'fileutils'

class Migrate
  @@dirs_to_copy = {'jekyll/_cci2' => 'hugo/content/english/2.0/',
                    'jekyll/_cci2_ja' => 'hugo/content/japanese/2.0/',
                    'jekyll/assets/img/' => "hugo/static/assets/img",
                   }

  @@dirs_to_delete = ["hugo/static/assets/img/docs/_unused"]
  @@md_syntax_mapping = {
    /\{\{\s*site.baseurl\s*\}\}/ => '{{< baseurl >}}',
    "endraw"                     => '/raw',
    /\{:\s*.no_toc/              => "{.no_toc",
    /\{:\s*class=/               => "{class=",
    /\{: #/                      => "{#",
    "* TOC"                      => "",
    /\{:toc\}/                   => "",
    /\{:.tab/                    => "{.tab"

  }

  def initialize
    copy_2_0
    replace_md_syntax
    migrate_asciidoc
    rename_indexs
    print_manual_work
  end


  # jekyll has an index.md, which hugo expects to be _index to differentiate it
  # as a "list" page type, rather than a" single
  def rename_indexs
    Dir.glob("hugo/content/**/index.md").each do |f|
      puts(f)
      File.rename(f, "_index.md")
    end
  end

  # glob all markdown files that were copied into hugo, open them, swap
  # instances of jekyll syntax for hugo.
  def replace_md_syntax
    @@dirs_to_copy.each do | _, hugo|
      files =  Dir.glob("#{hugo}/**/*.md")
      files.each do |f|
        file_text = File.read(f)
        @@md_syntax_mapping.each do |jekyll_syntax, hugo_syntax|
          file_text.gsub!(jekyll_syntax, hugo_syntax)
        end
        File.open(f, "w") { |file| file.puts file_text }
      end
    end
  end

  def has_frontmatter?(file_lines, f)
    if file_lines[0] != "---"
      return false
    end

    # make sure there is a matching output ---
    file_lines.drop(1).each do |line|
      if line == "---"
        return true
      end
    end
    raise "No closing front matter for file: #{f}"
  end

  # assumes you already have a file with frontmatter,
  def insert_into_frontmatter(item, file_lines, f)
    first_line = file_lines[0]
    return [first_line, item, file_lines[1..-1]]
  end

  # loop through lines and get first instance of top level title.
  def get_asciidoc_title(file_lines, f)
    title_regex = /^=[^=]/
    file_lines.each do |line|
      if line.match(title_regex)
        return line.split(title_regex)[1]
      end
    end
  end


  # The way we format asciidoc for jekyll is different than what hugo needs.
  # This method extracts the title syntax and turns it into front matter on our adoc files.
  def migrate_asciidoc
    @@dirs_to_copy.each do | _, hugo|
      adoc_files = Dir.glob("#{hugo}/**/*.adoc")
      adoc_files.each do |f|
        file_lines = File.readlines(f, chomp: true)
        title = get_asciidoc_title(file_lines, f)
        if has_frontmatter?(file_lines, f)
          output = insert_into_frontmatter("title: #{title}", file_lines, f)
          File.open(f, "w") { |file| file.puts output }
        else
          output = ["---\n", "title: \"#{title}\"", "---\n"] + file_lines
          File.open(f, "w") { |file| file.puts output }
        end
      end
    end
  end

  def print_manual_work
    puts ""
    puts "The following work needs to be done manually if this is the first time you are running this script: "
    puts "----------------------------------------------------------------"
    puts "- content/2.0/project-walkthrough.md has many {raw} tags that are inline and must be removed."
  end

  # copy over content
  def copy_2_0
    puts "copying content from jekyll to hugo:"
    @@dirs_to_copy.each do | jekyll, hugo |
      puts "copying #{jekyll} => #{hugo}"
      puts
      FileUtils.mkdir_p hugo # make the directory if doesn't exist yet.
      FileUtils.copy_entry jekyll, hugo
    end
    @@dirs_to_delete.each do | dir |
      FileUtils.remove_dir(dir)
    end
  end
end

Migrate.new
