require 'nokogiri'
require 'colored'

### Call like so: thor ti:project:new HelloWorld com.wix.helloworld iphone
module Ti
  TITANIUM_VERSION  = '1.6.2'
  OSX_TITANIUM = "/Library/Application\\ Support/Titanium/mobilesdk/osx/#{TITANIUM_VERSION}/titanium.py"

  class Project < Thor
    desc "new <name> <id> <platform>", "generates a new Titanium project."
    long_desc "Generates a new Titanium project. See 'ti help new' for more information.
              \n\nExamples:
              \n\nti new demo ==> Creates a new project with a default id (org.mycompany.demo) and sets the project platform to iphone.
              \n\nti new demo com.youwantit.dontyou ==> Creates a new project 'demo' with the id of 'com.youwantit.dontyou' to be used on the iphone.
              \n\nti new demo com.youwantit.dontyou ipad ==. Creates a new project 'demo' with the id 'com.youwantit.dontyou' for the ipad."
    def new(name, id='org.mycompany.demo', platform='iphone')
      Helpers.generate_project(name, id, platform)
      Helpers.display_project_info(name)
    end

  end

### TODO: Move this section to a seperate helpers.rb file
  class Helpers

    def self.generate_project(name, id, platform)
      puts "Generating a new Ti project...".blue
      if (generate_titanium_project(name, id, platform))
        puts "Generating the Rakefile...".blue
        generate_rakefile(name, id, platform)
        puts "Generating the tiapp.xml file...".blue
        generate_appconfig("#{name}/tiapp.xml", name, id)
        puts "Successfully created new Ti project".green
      else
        puts "Failed creating new Ti project".red
      end
    end

    def self.generate_appconfig(configfile, name, id)
      # copy the tiapp.xml file from templates
      `cp ti/templates/tiapp.xml #{name}/tiapp.xml`
      config = Ti::Config.new
      # Read all the existing values from the file
      config.parse("#{name}/tiapp.xml")
      # Override with new values
      config.id = id
      config.name = name
      # Write the new values to the file
      config.write(configfile)
    end

    def self.display_project_info(name)
      config = Ti::Config.new
      config.parse("#{name}/tiapp.xml")
      puts "Project Info:".green
      puts "Name: #{config.name}"
      puts "Id: #{config.id}"
      puts "Version: #{config.version}"
      puts "Publisher: #{config.publisher}"
      puts "Url: #{config.url}"
      puts "Description: #{config.description}"
      puts "Copyright: #{config.copyright}"
      puts "Icon: #{config.icon}"
      puts "Persistent-Wifi: #{config.persistent_wifi}"
      puts "Prerendered-Icon: #{config.prerendered_icon}"
      puts "Statusbar-Style: #{config.statusbar_style}"
      puts "Statusbar-Hidden: #{config.statusbar_hidden}"
      puts "Fullscreen: #{config.fullscreen}"
      puts "Navbar-Hidden: #{config.navbar_hidden}"
      puts "Analytics: #{config.analytics}"
      puts "Guid: #{config.guid}"
    end

    def self.generate_titanium_project(name, id, platform)
      system("#{Ti::OSX_TITANIUM} create --name=#{name} --platform=#{platform} --id=#{id}")
    end

    ### TODO: Instead of creating the whole Rakefile dynamically, we can keep a copy of the non-dynamic portions
    ### of the Rakefile in the templates folder. We then copy this partial file and open it and append the dynamic
    ### portions only using the following method.
    def self.generate_rakefile(project_name, app_id, app_device)
      rakefile = File.join(Dir.pwd, "#{project_name}/Rakefile")
      unless File.exists?(rakefile)
        File.open(rakefile, 'w') do |f|
          f.puts <<-LINE
require 'rubygems'
require 'colored'
require 'betabuilder'

PROJECT_NAME="#{project_name}"
PROJECT_ROOT = File.dirname(__FILE__)

IPHONE_SDK_VERSION="4.3"
TI_SDK_VERSION="1.6.2"
TI_DIR='/Library/Application\\ Support/Titanium'
TI_ASSETS_DIR="\#{TI_DIR}/mobilesdk/osx/\#{TI_SDK_VERSION}"
TI_IPHONE_DIR="\#{TI_ASSETS_DIR}/iphone"
TI_BUILD="\#{TI_IPHONE_DIR}/builder.py"
APP_DEVICE="#{app_device}"
APP_ID = "#{app_id}"
APP_NAME = "#{project_name}"

BetaBuilder::Tasks.new do |config|
  # App Name
  config.target = "#{project_name}"

  # Xcode configuration profile
  config.configuration = "Adhoc"

end

task :default => ["build:#{app_device}"]

namespace :setup do
  desc "Do all the setup procedures"
  task :all do
    Rake::Task['setup:xml'].invoke
    Rake::Task['setup:entitlements'].invoke
    Rake::Task['setup:rakefile'].invoke
  end

  desc "Copy the tiapp.xml file into build/iphone directory"
  task :xml do
    copy_xml
  end

  desc "Create the Entitlements.plist file in build/iphone directory"
  task :entitlements do
    create_entitlement_plist
  end

  desc "Copy the Rakefile to the build/iphone directory"
  task :rakefile do
    copy_rakefile
  end
end

namespace :compile do
  desc "Compile all assets"
  task :all do
    compile
  end

  desc "Compile Sass into JSS"
  task :styles do
    compile_sass
  end

  desc "Compile CoffeeScript into JS"
  task :coffee do
    compile_coffee
  end
end

namespace :build do
  desc "build the app for #{app_device}"
  task :#{app_device} do
    build
  end
end

def compile
  compile_coffee && compile_sass
end

def copy_xml
  unless File.exists?(File.join(Dir.pwd, 'build/iphone/tiapp.xml'))
    puts "Copying tiapp.xml to the build/iphone/ directory.".blue
    system("ln -s \#{File.join(Dir.pwd, 'tiapp.xml')} \#{File.join(Dir.pwd, 'build/iphone')}")
  end
end

def create_entitlement_plist
  entitlements = File.join(Dir.pwd, 'build/iphone/Entitlements.plist')
  unless File.exists?(entitlements)
    puts "Creating an Entitlements.plist (build/iphone) file since doesn't exist.".blue
    File.open(entitlements, 'w') do |f|
      f.puts "FIGURE OUT HOW TO PUT THE FILE CONTENTS."
    end
  end
end

def copy_rakefile
  unless File.exists?(File.join(Dir.pwd, 'build/iphone/Rakefile'))
    puts "Copying Rakefile to the build/iphone/directory.".blue
    system("ln -s \#{File.join(Dir.pwd, 'Rakefile')} \#{File.join(Dir.pwd, 'build/iphone')}")
  end
end

def compile_sass
  puts "Compiling stylesheets".blue
  compilation = system "sass --compass -C -t expanded stylesheets/app.sass > Resources/app.jss"
end

def compile_coffee
  puts "Compiling CoffeeScript".blue
  paths = `find src/#{project_name} -name '*.coffee'`.split("\\n")
  compilation = (
    system "coffee -p --join --bare \#{paths.join(' ')} > Resources/turvy.js" and
    system "coffee -p --bare src/app.coffee > Resources/app.js"
  )

  if compilation
    puts "Successfully compiled CoffeeScript".green
  else
    puts "Error compiling CoffeeScript".red
  end
  compilation
end

def build(options={})
  return unless compile
  options[:device] ||= '#{app_device}'
  puts "Building with Titanium... (DEVICE_TYPE:\#{options[:device]})".blue
  sh %Q{bash -c "\#{TI_BUILD} run \#{PROJECT_ROOT}/ \#{IPHONE_SDK_VERSION} \#{APP_ID} \#{APP_NAME} \#{APP_DEVICE}" \\
| perl -pe 's/^\\\\[DEBUG\\\\].*$/\\\\e[35m$&\\\\e[0m/g;s/^\\\\[INFO\\\\].*$/\\\\e[36m$&\\\\e[0m/g;s/^\\\\[WARN\\\\].*$/\\\\e[33m$&\\\\e[0m/g;s/^\\\\[ERROR\\\\].*$/\\\\e[31m$&\\\\e[0m/g;'}

end

          LINE
        end
      end

    end

  end
end

### TODO: Move this section to a seperate config.rb file
require 'nokogiri'

module Ti
  class Config
    attr_accessor :id, :name, :version, :publisher, :url, :description, :copyright, :icon, :persistent_wifi, :prerendered_icon,
                  :statusbar_style, :statusbar_hidden, :fullscreen, :navbar_hidden, :analytics, :guid

    def parse(filename)
      xml  = File.open(filename)
      doc    = Nokogiri::XML(xml)
      xml.close
      # parse into properties
      @id = doc.at_css("id").content
      @name = doc.at_css("name").content
      @version = doc.at_css("version").content
      @publisher = doc.at_css("publisher").content
      @url = doc.at_css("url").content
      @description = doc.at_css("description").content
      @copyright = doc.at_css("copyright").content
      @icon = doc.at_css("icon").content
      @persistent_wifi = doc.at_css("persistent-wifi").content
      @prerendered_icon = doc.at_css("prerendered-icon").content
      @statusbar_style = doc.at_css("statusbar-style").content
      @statusbar_hidden = doc.at_css("statusbar-hidden").content
      @fullscreen = doc.at_css("fullscreen").content
      @navbar_hidden = doc.at_css("navbar-hidden").content
      @analytics = doc.at_css("analytics").content
      @guid = doc.at_css("guid").content
    end

    def write(filename)
      xml  = File.open(filename)
      doc    = Nokogiri::XML(xml)
      xml.close
      ## modify the contents of the xml based on property values
      doc.at_css("id").content = @id
      doc.at_css("name").content = @name
      doc.at_css("version").content = @version
      doc.at_css("publisher").content = @publisher
      doc.at_css("url").content = @url
      doc.at_css("description").content = @description
      doc.at_css("copyright").content = @copyright
      doc.at_css("icon").content = @icon
      doc.at_css("persistent-wifi").content = @persistent_wifi
      doc.at_css("prerendered-icon").content = @prerendered_icon
      doc.at_css("statusbar-style").content = @statusbar_style
      doc.at_css("statusbar-hidden").content = @statusbar_hidden
      doc.at_css("fullscreen").content = @fullscreen
      doc.at_css("navbar-hidden").content = @navbar_hidden
      doc.at_css("analytics").content = @analytics
      doc.at_css("guid").content = @guid
      File.open(filename, 'w') do |f|
        f.puts doc.to_xml
      end
    end

  end
end