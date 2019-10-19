require 'json'
require 'net/http'
require 'net/https'

class GithubClient

    BASE_URL = 'https://api.github.com' 

    def repository(owner: nil, name: nil, url: nil)
        if owner && name 
            get "/repos/:owner/:name", owner: owner, name: name
        elsif url
            uri = URI.parse url
            get(File.join('/repos', uri.path))
        else
            raise "Invalid arguments"
        end
    end

    def get(path, **opts)
        url = make_url path, **opts
        uri = URI.parse url
        client = Net::HTTP.new uri.host, uri.port
        client.use_ssl = uri.scheme.downcase == 'https'
        res = client.get uri.path
        return nil if !res || !res.is_a?(Net::HTTPOK)
        begin
            body = res.body
            JSON.parse body, symbolize_names: true
        rescue Exception => e
            STDERR.puts "Failed!"
            STDERR.puts e
            nil
        end
    end

    def make_url(path, **opts)
        opts.each{|name, val|
            path = path.gsub ":#{name}", val.to_s
        }
        File.join BASE_URL, path
    end

end
