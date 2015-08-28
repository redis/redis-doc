task :default => [:parse]

task :parse do
  require "json"
  require "batch"

  Dir["**/*.json"].each do |file|
    JSON.parse(File.read(file))
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
