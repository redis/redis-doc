task :default => [:parse, :spellcheck]

task :parse do
  require "json"
  require "batch"
  require "rdiscount"

  Batch.each(Dir["**/*.json"] + Dir["**/*.md"]) do |file|
    if File.extname(file) == ".md"
      RDiscount.new(File.read(file)).to_html
    else
      JSON.parse(File.read(file))
    end
  end
end

task :spellcheck do
  require "json"

  `mkdir -p tmp`

  IO.popen("aspell --lang=en create master ./tmp/dict", "w") do |io|
    words = JSON.parse(File.read("commands.json")).
              keys.
              map { |str| str.split(/[ -]/) }.
              flatten(1)

    io.puts(words.join("\n"))
    io.puts(File.read("wordlist"))
  end

  Dir["**/*.md"].each do |file|
    command = %q{
      ruby -pe 'gsub /^    .*$/, ""' |
      ruby -pe 'gsub /`[^`]+`/, ""' |
      ruby -e 'puts $stdin.read.gsub /\[([^\]]+)\]\(([^\)]+)\)/m, "\\1"' |
      aspell -H -a --extra-dicts=./tmp/dict 2>/dev/null
    }

    words = `cat '#{file}' | #{command}`.lines.map do |line|
      line[/^& ([^ ]+)/, 1]
    end.compact

    puts "#{file}: #{words.uniq.sort.join(" ")}" if words.any?
  end
end

namespace :format do

  def format(file)
    require "./remarkdown"

    return unless File.exist?(file)

    STDOUT.print "formatting #{file}..."
    STDOUT.flush

    body = File.read(file)
    body = ReMarkdown.new(body).to_s
    body = body.gsub(/^\s+$/, "")

    File.open(file, "w") do |f|
      f.print body
    end

    STDOUT.puts
  end

  desc "Reformat single file"
  task :file, :path do |t, args|
    format(args[:path])
  end

  desc "Reformat changes staged for commit"
  task :cached do
    `git diff --cached --name-only -- commands/`.split.each do |path|
      format(path)
    end
  end

  desc "Reformat everything"
  task :all do
    Dir["commands/*.md"].each do |path|
      format(path)
    end
  end
end
