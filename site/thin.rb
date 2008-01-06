require 'rubygems'
require 'atchoum'

class Thin < Atchoum::Website
  ROOT = ENV['SITE_ROOT'] || '/'
  
  def layout
    xhtml_html do
      head do
        title 'Thin - yet another web server'
        link :rel => 'stylesheet', :href => "#{ROOT}/style.css", :type => 'text/css'
      end
      body do
        ul.menu! do
          li { a 'about', :href => "#{ROOT}/" }
          li { a 'download', :href => "#{ROOT}/download/" }
          li { a 'usage', :href => "#{ROOT}/usage/" }
          li { a 'doc', :href => "#{ROOT}/doc/" }
          li { a 'community', :href => "http://groups.google.com/group/thin-ruby/" }
        end

        div.container! do
          div.header! do
            a(:href => :index, :title => 'home') do
              img.logo! :src => "#{ROOT}/images/logo.gif", :alt => 'Thin'
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
    p 'Thin is a Ruby web server that glues together 3 of the best Ruby libraries in web history:'
    ul do
      li do
        text "the #{a 'Mongrel parser', :href => 'http://www.zedshaw.com/tips/ragel_state_charts.html'}"
        text ", the root of #{a 'Mongrel', :href => 'http://mongrel.rubyforge.org/'} speed and security"
      end
      li do
        a "Event Machine", :href => 'http://rubyeventmachine.com/'
        text ", a network I/O library with extremely high scalability, performance and stability"
      end
      li do
        a "Rack", :href => 'http://rack.rubyforge.org/'
        text ", a minimal interface between webservers and Ruby frameworks"
      end
    end
    p <<-EOS
      Which makes it, with all humility, the most secure, stable, fast and extensible Ruby web server
      bundled in an easy to use gem for your own pleasure.
    EOS
    
    h2 'Why'
    div.graph do
      h3 'Request / seconds comparison'
      img :alt => 'Chart', :title => 'Benchmarks', :src => chart_url([
        ['WEBrick',     [297.37, 296.65, 297.16]],
        ['Mongrel',     [556.67, 622.90, 428.23]],
        ['Evented M.',  [517.97, 657.89, 656.17]],
        ['Thin',        [719.53, 782.11, 776.40]]
      ], :min => 200, :scale => 6.5, :size => '350x150', :width => 16,
         :colors => %w(000000 666666 cccccc),
         :legends => ['1 c req.', '10 c req.', '100 c req.'])
      em 'c req. = Concurrency Level (number of simultaneous requests)'
    end
    
    h2 'How'
    pre 'sudo gem install thin'

    p 'Go to your Rails app directory and run:'
    pre 'thin start'
  end
  
  def download_page
    h2 'Install the Gem'

    p 'To install the latest stable gem'
    pre 'sudo gem install thin'
    
    h2 'Install from source'

    p 'Clone the Git repository'
    pre 'git clone http://code.macournoyer.com/git/thin.git'
    
    p 'Or checkout the Subversion mirror (might be out of date)'
    pre 'svn co http://code.macournoyer.com/svn/thin/trunk thin'
    
    p 'Hack the code, patch it, whatever, build the Gem and install'
    pre 'cd thin && rake install'
  end
  
  def usage_page
    h2 'Usage'

    p { "After installing the Gem, a #{code 'thin'} script should be in your " +
        "path to easily start your Rails application." }

    pre "cd to/your/rails/app\nthin start"
    
    p { "But Thin is also usable through Rack #{code 'rackup'} command. You need " +
        "to setup a #{code 'config.ru'} file and require thin in it." }

    em.filename 'config.ru'
    pre <<-EOS.gsub(/^\s{6}/, '')
      require 'thin'
      
      app = proc do |env|
        [ 200, { 'Content-Type' => 'text/html' }, ['hi'] ]
      end
      
      run app
    EOS
    
    pre 'rackup -s thin'
    
    p { "See #{a 'Rack doc', :href => 'http://rack.rubyforge.org/doc/'} for more." }
  end
  
  private
  
    def chart_url(data, options={})
      size   = options[:size]  || '250x150'
      width  = options[:width] || 50
      min    = options[:min]   || 0
      scale  = options[:scale] || 1.0
      colors = options[:colors] || '000000'
      legends = options[:legends]
    
      data_matrix  = data.collect { |d| Array(d[1]) }
      chart_matrix = data_matrix[0].zip(*data_matrix[1..-1]) # transpose the matrix
      chart_data   = chart_matrix.collect { |c| c.collect { |d| (d - min) / scale }.join(',') }.join('|')
      labels       = data.collect{|d|d[0]}.join('|')
    
      "http://chart.apis.google.com/chart?cht=bvg&chd=t:#{chart_data}&chbh=#{width}&chs=#{size}&chl=#{labels}&chco=#{colors.join(',')}&chdl=#{legends.join('|')}"
    end
end