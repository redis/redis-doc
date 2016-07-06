require "net/http"
require "uri"

module Clients
  def self.check(clients)
    errors = []

    workers = clients.map do |client|
      Thread.new do
        Thread.current.abort_on_exception = true

        Checker.new(client, errors).check
      end
    end

    workers.each(&:join)

    if errors.empty?
      puts("All is good.")
    else
      errors.group_by(&:first).each do |client, group|
        puts(client[:name])

        group.each do |_, message|
          puts(sprintf("  %s", message))
        end
      end

      exit(1)
    end
  end

  class Checker
    def initialize(client, errors)
      @client = client
      @errors = errors
    end

    def check
      if @client[:url]
        check_url(@client[:url])
      end

      if @client[:repository]
        check_url(@client[:repository])
      end

      if assert(@client[:authors], "authors is null")
        @client[:authors].each do |author|
          check_author(author)
        end
      end
    end

    def check_url(url)
      uri = URI(url)

      if uri.scheme == "http" || uri.scheme == "https"
        begin
          res = Net::HTTP.get_response(uri)

          assert(res.code == "200" || res.code == "302", sprintf("URL broken: %s (%s)", url, res.code))
        rescue OpenSSL::SSL::SSLError
          assert(false, sprintf("SSL Error for URL: %s", url))
        end
      end
    end

    def check_author(name)
      valid = assert(name && name.size > 0 && name =~ /^\w+$/, sprintf("Invalid author %s", name.inspect))

      if valid
        uri = URI(sprintf("http://twitter-avatars.herokuapp.com/avatar/%s", name))

        res = Net::HTTP.get_response(uri)

        assert(res.code == "302", sprintf("Invalid Twitter account: %s", name))
      end
    end

    def assert(assertion, message)
      assertion || (@errors.push([@client, message]) && false)
    end
  end
end

if $0 == __FILE__
  require 'json'
  file = ARGV.shift
  if file.nil?
    puts "Usage: #{$0} [file]"
    exit(1)
  end

  puts "Checking #{file}..."
  clients = JSON.parse(File.read(file), :symbolize_names => true)
  Clients.check(clients)
end
