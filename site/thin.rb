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
          li { a 'group', :href => "http://groups.google.com/group/thin-ruby/" }
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
    p 'Thin is a Ruby web server that glues togeter 3 of the best Ruby libraries in web history:'
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
      bundled in an easy to use gem for your own plesure.
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