task :default => :parse

task :parse do
  require "json"
  require "batch"

  Batch.each(Dir["**/*.json"]) do |file|
    JSON.parse(File.read(file))
  end
end
