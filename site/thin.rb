require 'rubygems'
require 'atchoum'

class Thin < Atchoum::Website
  ROOT = ENV['SITE_ROOT'] || ''
  
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
          li { a 'code', :href => "http://github.com/macournoyer/thin/" }
          li { a 'bugs', :href => "http://thin.lighthouseapp.com/projects/7212-thin/" }
          li { a 'users', :href => "#{ROOT}/users/" }
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

    p { "Clone the #{a 'Git repository', :href => 'http://github.com/macournoyer/thin/'}" }
    pre "git clone git://github.com/macournoyer/thin.git"
    
    p 'Hack the code, patch it, whatever, build the Gem and install'
    pre "cd thin\nsudo rake install"
  end
  
  def usage_page
    h2 'Using with Rails'

    p { "After installing the Gem, a #{code 'thin'} script should be in your " +
        "path to easily start your Rails application." }

    pre "cd to/your/rails/app\nthin start"
    
    h2 'Using with anything, ANYTHING!'
    
    p "But Thin can also load Rack config file so you can use it with any framework that " +
      "supports Rack. Even your own that is, like, soooo much better then Rails, rly!"

    em.filename 'fart.ru'
    pre <<-EOS.gsub(/^\s{6}/, '')
      app = proc do |env|
        [
          200,          # Status code
          {             # Response headers
            'Content-Type' => 'text/html',
            'Content-Length' => '2',
          },
          ['hi']        # Response body
        ]
      end
      
      # You can install Rack middlewares
      # to do some crazy stuff like logging,
      # filtering, auth or build your own.
      use Rack::CommonLogger
      
      run app
    EOS
    
    pre 'thin start -R fart.ru'
    p { "See #{a 'Rack doc', :href => 'http://rack.rubyforge.org/doc/'} for more." }
    
    hr
    
    h2 'Deploying'
    
    p 'Deploying a cluster of Thins is super easy. Just specify the number of servers you ' + 
      'want to launch.'
    pre 'thin start --servers 3'
    
    p 'You can also install Thin as a runlevel script (under /etc/init.d/thin) that will start all your servers after boot.'
    pre 'sudo thin install'
    
    p 'and setup a config file for each app you want to start:'
    pre 'thin config -C /etc/thin/myapp.yml -c /var/...'
    
    p { "Run #{code 'thin -h'} to get all options." }
    
    h2 'Behind Nginx'
    
    p { "Check out this #{a 'sample Nginx config', :href => 'http://brainspl.at/nginx.conf.txt'} " +
        "file to proxy requests to a Thin backend." }
    
    p 'then start your Thin cluster like this:'
    pre 'thin start -s3 -p 5000'
    
    p 'You can also setup a Thin config file and use it to control your cluster:'
    pre "thin config -C myapp.yml -s3 -p 5000\nthin start -C myapp.yml"
    
    p 'To connect to Nginx using UNIX domain sockets edit the upstream block in your nginx config file:'
    
    em.filename 'nginx.conf'
    pre <<-EOS.gsub(/^\s{6}/, '')
      upstream  backend {
         server   unix:/tmp/thin.0.sock;
         server   unix:/tmp/thin.1.sock;
         server   unix:/tmp/thin.2.sock;
      }
    EOS
    
    p 'and start your cluster like this:'
    pre 'thin start -s3 --socket /tmp/thin.sock'
  end
  
  def users_page
    h2 'Users'
    
    p "Who's using Thin ?"
    
    ul do
      li { a 'HostingRails', :href => 'http://www.hostingrails.com/mongrel_and_thin_hosting' }
      li { a 'RefactorMyCode.com', :href => 'http://refactormycode.com/' }
      li { a "Standout Jobs", :href => 'http://standoutjobs.com/'}
      li { a "Kevin Williams Blog", :href => 'http://www.almostserio.us/articles/tag/thin' }
      li { a "Gitorious", :href => 'http://gitorious.org/' }
      li { a "Dinooz", :href => 'http://www.nicomoayudarte.com/' }
      li { a "Mobile Dyne Systems", :href => 'http://www.mobiledyne.com/' }
      li { a "feelfree.homelinux.com", :href => 'http://feelfree.homelinux.com' }
      li { a "to2posts.com", :href => 'http://to2blogs.com/' }
      li { a "James on Software", :href => 'http://jamesgolick.com/' }
      li { a "FlashDen", :href => 'http://flashden.net/' }
      li { a "Calico Web Development", :href => 'http://www.calicowebdev.com/' }
      li { a "Cornerstone Web", :href => 'http://www.cornerstoneweb.org/' }
      li { a "Osmos", :href => 'http://www.getosmos.com/' }
      li { a "Lipomics", :href => 'http://www.lipomics.com/' }
      li { a "Joao Pedrosa's Blog", :href => 'http://www.deze9.com/jp/blog/post?p=enabling-thin-support-for-this-site-replacing' }
      li { a "RaPlanet", :href => 'http://planet.zhekov.net/' }
      li { a "Ninja Hideout blog", :href => 'http://blog.ninjahideout.com/' }
      li { a "Hoodows Blog", :href => 'http://blog.hoodow.de/articles/2008/02/09/thin' }
      li { a "moonitor.org", :href => 'http://moonitor.org' }
      li { a "Daniel Fischer's Blog", :href => 'http://www.danielfischer.com/' }
      li { a "RoundHaus", :href => 'http://www.roundhaus.com/' }
      li { a "Socks and Sandals", :href => 'http://blog.cbcg.net/' }
      li { a "indiagoes", :href => 'http://www.indiagoes.com/' }
      li { a "ajaxwhois", :href => 'http://ajaxwhois.com/' }
      li { a "Sproglogs", :href => 'http://sproglogs.com/' }
      li { a "Look to the Stars", :href => 'http://www.looktothestars.org/' }
      li { a "kluster", :href => 'http://kluster.com'}
      li { a "SocialSpark", :href => 'http://socialspark.com'}
      li { a "Tanga.com", :href => 'http://tanga.com'}
      li { a "Opening Times", :href => 'http://opening-times.co.uk/'}
      li { a "p0pulist", :href => 'http://p0pulist.com/'}
      li { a "pickhost.eu", :href => 'http://pickhost.eu'}
      li { a "HowFlow", :href => 'http://howflow.com/'}
      li { a "boo-widgets", :href => 'http://boo-box.com/site/en/widget/get'}
      li { a "BigCity.cz", :href => 'http://www.bigcity.cz/'}
      li { a "yabadaba.ru", :href => 'http://yabadaba.ru/'}
      li { a "Freebootr.com", :href => 'http://freebootr.com/'}
      li { a "Hacknight", :href => 'http://hacknight.gangplankhq.com/'}
      li { a "Sizzix", :href => 'http://www.sizzix.com/'}
      li { a "Ellison Retailers", :href => 'http://www.ellisonretailers.com/'}
      li { a "ShareMeme", :href => 'http://sharememe.com/'}
      li { a "ylastic", :href => 'http://ylastic.com/'}
      li { a "hello2morrow", :href => 'http://www.hello2morrow.com/'}
      li { a "TimmyOnTime", :href => 'http://www.timmyontime.com/'}
      li { a "Generous", :href => 'http://generous.org.uk/'}
      li { a "Catapult Magazine", :href => 'http://www.catapultmagazine.com/'}
      li { a "Good-Tutorials", :href => 'http://www.good-tutorials.com/'}
    end
    
    p { "If you'd like to have your site listed here, #{a 'drop me an email', :href => 'mailto:macournoyer@gmail.com'}" }
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