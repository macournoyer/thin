require 'rubygems'
require 'atchoum'

class Thin < Atchoum::Website
  def layout
    xhtml_html do
      head do
        title 'Thin - yet another web server'
        link :rel => 'stylesheet', :href => 'style.css', :type => 'text/css'
      end
      body do
        ul.menu! do
          li { a 'home', :href => "/thin/" }
          li { a 'doc', :href => "/thin/doc/" }
          li { a 'timeline', :href => "/thin/trac.fcgi/timeline" }
          li { a 'code', :href => "/thin/trac.fcgi/browser" }
          li { a 'tickets', :href => "/thin/trac.fcgi/report" }
          li { a 'new ticket', :href => "/thin/trac.fcgi/newticket" }
        end

        div.container! do
          div.header! do
            a(:href => :index, :title => 'home') do
              img.logo! :src => 'images/logo.gif', :alt => 'Thin'
            end
            h2.tag_line! "A fast and very simple Ruby web server"
          end
        
          div.content! do
            self << yield
          end

          div.footer! do
            hr
            text "&copy; "
            a(:href => 'http://macournoyer.com') { 'Marc-Andr&eacute; Cournoyer' }
          end
        end
      end
    end
  end
  
  def index_page
    h2 'What'
    p do
      <<-EOS
        Thin is a #{acronym('very simple', :title => 'under 1500 LOC')} web server written in Ruby.
        It's single-threaded, which means it can only serve one request at a time.
        This simplicity affords increased speed and decreased memory usage for singled-threaded framework like
        #{a 'Rails', :href => 'http://rubyonrails.org', :title => 'Ruby on Rails web framework'}.
      EOS
    end
    p "It's the fastest and simplest way to serve your Rails application right now!"
    
    h2 'Why'
    ul do
      li { "10 % faster then #{a 'Mongrel', :href => 'http://mongrel.rubyforge.org/', :title => 'Mongrel web server'}" }
      li { "2 MB less memory then Mongrel" }
      li { "No C extension, 100% pure and beautiful Ruby" }
      li { "No dependencies" }
      li { "Built-in cluster monitoring" }
    end
    
    h2 'How'
    pre 'sudo gem install thin --source http://code.macournoyer.com'

    p 'Go to your Rails app directory and run:'
    pre 'thin start'
  end
end