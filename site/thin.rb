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
          li { a 'code', :href => "/svn/thin/" }
          li { a 'group', :href => "http://groups.google.com/group/thin-ruby/" }
          li { a 'trac', :href => "/thin/trac.fcgi" }
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
        Thin is a web server written entirely in Ruby in the #{acronym('simplest', :title => 'under 2 KLOC')} way possible.
        It does as little as possible to serve your #{a 'Rails', :href => 'http://rubyonrails.org', :title => 'Ruby on Rails web framework'} application,
        which makes it one of the fastest Rails server out there.
      EOS
    end
    
    h2 'Why'
    ul do
      li { "10 % faster than #{a 'Mongrel', :href => 'http://mongrel.rubyforge.org/', :title => 'Mongrel web server'}" }
      li { "5 MB less memory than Mongrel" }
      li { "No C extension, 100% pure and beautiful Ruby" }
      li { "No dependency" }
      li { "Built-in cluster monitoring" }
      li { "0 downtime cluster restart" }
    end
    
    h2 'How'
    pre 'sudo gem install thin'

    p 'Go to your Rails app directory and run:'
    pre 'thin start'
  end
end