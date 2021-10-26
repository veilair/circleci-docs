#!/usr/bin/env ruby

require 'fileutils'

class Migrate
  @@dirs_to_copy = {'jekyll/_cci2' => 'hugo/content/2.0',
                    'jekyll/assets' => "hugo/static",
                   }
  @@replacements_to_make = {
    /\{\{\s*site.baseurl\s*\}\}/ => '{{< baseurl >}}',
    "endraw"                     => '/raw',
    /\{:\s*.no_toc/              => "{.no_toc}",
    /\{:\s*class=/               => "{class=",
    /\{: #/                      => "{#",
    "* TOC"                      => "",
    /\{:toc\}/                   => "",
    /\{:.tab/                    => "{.tab"

  }

  def initialize
    copy_2_0
    replace_syntax
    rename_index
    print_manual_work
  end

  def get_markdown_files(dir)
    return Dir.glob("#{dir}/**/*.md")
  end

  # jekyll has an index.md, which hugo expects to be _index to differentiate it
  # as a "list" page type, rather than a" single
  def rename_index
    File.rename("hugo/content/2.0/index.md", "hugo/content/2.0/_index.md") if File.file?("hugo/content/2.0/index.md")
  end

  # iterate on all markdown files,
  # open them, and for each jekyll syntax type, change it to hugo's equivalent.
  def replace_syntax
    ## for each dir that moved to hugo...
    @@dirs_to_copy.each do | _, hugo|
      ## glob all md files and
      files = get_markdown_files(hugo)
      ## open each file, and for each replacement, make the replacement.
      files.each do |f|
        file_text = File.read(f)
        replaced_text = ""
        @@replacements_to_make.each do |jekyll_syntax, hugo_syntax|
          replaced_text = file_text.gsub!(jekyll_syntax, hugo_syntax)
          File.open(f, "w") { |file| file.puts replaced_text }
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
      FileUtils.copy_entry jekyll, hugo
    end
  end
end

Migrate.new
