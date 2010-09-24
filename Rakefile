task :default => :parse

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
