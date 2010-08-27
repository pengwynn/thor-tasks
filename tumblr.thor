require 'octopussy'
require 'buzzsprout'


module Tumblr
  class Post < Thor
    include Thor::Actions
    
    map "-r" => :repo
    map "-e" => :episode
    
    desc "repo URL", "Posts a link to a GitHub repo to Tumblr"
    def repo(url)
      slug = url.split("/").reverse[0..1].reverse.join("/")
      
      tags = ask("tags:")
      tags = tags.split(",").map(&:strip).unshift('github').uniq
      
      post_path = slug.gsub('/', '_')
      begin
        if not File.exists?(post_path) or yes?("File exists, overwrite?")
          repo = Octopussy.repo(url)
          raise "Repo not found" unless repo
          name = "#{repo.name}: #{repo.description}"
          slug = name.downcase.gsub(/[^a-z1-9]+/, '-').chomp('-')
          post  = <<-repo_post
---
name: "#{name}"
tags: #{tags.join(",")}
slug: #{slug}
state: draft
format: markdown
---
http://github.com/#{url}

[[Source on GitHub](http://github.com/#{url})]
repo_post
          open(File.join("#{post_path}.md"),'w') do |f|
            f.puts post
          end
        end
      rescue Exception => e
        say e.message
      end
    end
  
  end
end