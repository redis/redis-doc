#!/usr/bin/env ruby
require 'json'
require 'time'
libpath =  File.expand_path(File.dirname(__FILE__))
load File.join(libpath, 'github.rb')

module Modules

    def Modules::update_stars(module_file)
        puts "Updating stars at #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
        client = GithubClient.new
        json = File.read module_file
        modules = JSON.parse json, symbolize_names: true
        need_update = false
        modules.each{|mod|
            name = mod[:name]
            repo_url = mod[:repository]
            if !repo_url || repo_url.strip.empty?
                STDERR.puts "WARN: missing 'repository' in module: #{name}"
                next
            end
            puts "Updating #{name}..."
            info = client.repository url: repo_url
            if !info
                STDERR.puts "WARN: failed to fetch info for #{name}"
                next
            end
            stars = info[:stargazers_count].to_i
            current_stars = mod[:stars].to_i
            next if stars == 0
            puts "Stars: #{stars}, Current stars: #{current_stars}"
            if stars != current_stars
                need_update = true
                mod[:stars] = stars
            end
        }
        if need_update
            puts "Updating #{module_file}"
            File.open(module_file, 'w:utf-8'){|f|
                f.write(JSON.pretty_generate(modules))
            }
            puts "Done!"
        end
    end

end

if $0 == __FILE__
    action = ARGV.shift
    if action.nil?
        puts "Usage: #{$0} ACTION"
        puts "ACTIONS:"
        puts "    update_stars"
        exit(1)
    end

    if action == 'update_stars'
        module_file = File.join(File.dirname(libpath), 'modules.json')
        Modules::update_stars module_file
    end

end
