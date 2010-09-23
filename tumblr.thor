require 'octopussy'
require 'buzzsprout'


module Tumblr
  
  class Post < Thor
    include Thor::Actions
    
    map "-r" => :repo
    map "-e" => :episode
    
    desc "plain filename", "Creates a plain Tumblr post"
    def plain(filename)

      tags = ask("tags:")
      tags = tags.split(",").map(&:strip).uniq

      post_path = filename
      begin
        if not File.exists?(post_path) or yes?("File exists, overwrite?")
          post  = <<-post
---
name: 
tags: #{tags.join(",")}
slug: 
state: draft
format: markdown
---

post
          open(File.join("#{post_path}.md"),'w') do |f|
            f.puts post
          end
        end
      rescue Exception => e
        say e.message
      end
    end
    
    desc "repo URL", "Posts a link to a GitHub repo to Tumblr"
    def repo(url)
      github_slug = url.split("/").reverse[0..1].reverse.join("/")
      
      tags = ask("tags:")
      tags = tags.split(",").map(&:strip).unshift('github').uniq
      
      post_path = github_slug.gsub('/', '_')
      begin
        if not File.exists?(post_path) or yes?("File exists, overwrite?")
          repo = Octopussy.repo(github_slug)
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
http://github.com/#{github_slug}

[[Source on GitHub](http://github.com/#{github_slug})]
repo_post
          open(File.join("#{post_path}.md"),'w') do |f|
            f.puts post
          end
        end
      rescue Exception => e
        say e.message
      end
    end
    
    desc "episode URL", "Post a buzzsprout episode to Tumblr"
    def episode(url)
      begin
        episode = Buzzsprout.episode_from_url(url)
        slug = url.split("/").last.split("-")[1..-1].join("-")
        tags = episode.tags.unshift("episode").uniq
        post_path = slug
        if not File.exists?(post_path) or yes?("File exists, overwrite?")
          post  = <<-episode_post
---
name: "#{episode.title}"
tags: #{tags.join(",")}
slug: #{slug}
state: draft
format: markdown
---
#{url}
#{episode.description}

[Download MP3](#{url + '.mp3'})

Items mentioned in the show:
episode_post
          open(File.join("#{post_path}.md"),'w') do |f|
            f.write post
          end
        end
      rescue Exception => e
        say e.message
      end
    end
  
  end
end