# Based on Camping flipbook_rdoc by _why.
# http://code.whytheluckystiff.net/svn/camping/trunk/extras/flipbook_rdoc.rb

SITE_DIR = File.expand_path(File.dirname(__FILE__))

module Generators
  class HTMLGenerator
    def generate_html
      @files_and_classes = {
        'allfiles'     => gen_into_index(@files),
        'allclasses'   => gen_into_index(@classes),
        "initial_page" => main_url,
        'realtitle'    => CGI.escapeHTML(@options.title),
        'charset'      => @options.charset
      }

      # the individual descriptions for files and classes
      gen_into(@files)
      gen_into(@classes)
      gen_main_index
      
      # this method is defined in the template file
      write_extra_pages if defined? write_extra_pages
    end

    def gen_into(list)
      hsh = @files_and_classes.dup
      list.each do |item|
        if item.document_self
          op_file = item.path
          hsh['root'] = item.path.split("/").map { ".." }[1..-1].join("/")
          item.instance_variable_set("@values", hsh)
          File.makedirs(File.dirname(op_file))
          File.open(op_file, "w") { |file| item.write_on(file) }
        end
      end
    end

    def gen_into_index(list)
      res = []
      list.each do |item|
        hsh = item.value_hash
        hsh['href'] = item.path
        hsh['name'] = item.index_name
        res << hsh
      end
      res
    end

    def gen_main_index
      template = TemplatePage.new(RDoc::Page::INDEX)
      File.open("index.html", "w") do |f|
        values = @files_and_classes.dup
        if @options.inline_source
          values['inline_source'] = true
        end
        template.write_html_on(f, values)
      end
      ['logo.gif'].each do |img|
          ipath = File.join(SITE_DIR, 'images', img)
          File.copy(ipath, img)
      end
    end
  end
end


module RDoc
module Page
######################################################################
#
# The following is used for the -1 option
#

FONTS = "verdana,arial,'Bitstream Vera Sans',helvetica,sans-serif"

STYLE = File.read(SITE_DIR + '/style.css')

CONTENTS_XML = %{
IF:description
%description%
ENDIF:description

IF:requires
<strong>Requires:</strong>
START:requires
IF:aref
<a href="%aref%">%name%</a> 
ENDIF:aref
IFNOT:aref
%name%
ENDIF:aref 
END:requires
</ul>
ENDIF:requires

IF:attributes
<h4>Attributes</h4>
<table>
START:attributes
<tr><td>%name%</td><td>%rw%</td><td>%a_desc%</td></tr>
END:attributes
</table>
ENDIF:attributes

IF:includes
<h4>Includes</h4>
<ul>
START:includes
IF:aref
<li><a href="%aref%">%name%</a></li>
ENDIF:aref
IFNOT:aref
<li>%name%</li>
ENDIF:aref 
END:includes
</ul>
ENDIF:includes

START:sections
IF:method_list
<h2 class="ruled">Methods</h2>
START:method_list
IF:methods
START:methods
<h4 class="ruled">
<span class="method-type" title="%type% %category% method">%type% %category%</span>
IF:callseq
<strong><a name="%aref%" href="#%aref%" title="Permalink to %callseq%">%callseq%</a></strong>
ENDIF:callseq
IFNOT:callseq
<strong><a name="%aref%" href="#%aref%" title="Permalink to %type% %category% method: %name%">%name%%params%</a></strong>
ENDIF:callseq
</h4>

IF:m_desc
%m_desc%
ENDIF:m_desc

IF:sourcecode
<div class="sourcecode">
  <p class="source-link">[ <a href="javascript:toggleSource('%aref%_source')" id="l_%aref%_source">show source</a> ]</p>
  <div id="%aref%_source" class="dyn-source">
<pre>
%sourcecode%
</pre>
  </div>
</div>
ENDIF:sourcecode
END:methods
ENDIF:methods
END:method_list
ENDIF:method_list
END:sections
}

############################################################################


BODY = %{
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <title>
IF:title
  %realtitle% &raquo; %title%
ENDIF:title
IFNOT:title
  %realtitle%
ENDIF:title
  </title>
  <meta http-equiv="Content-Type" content="text/html; charset=%charset%" />
  <link rel="stylesheet" href="%style_url%" type="text/css" media="screen" />
  <script language="JavaScript" type="text/javascript">
    // <![CDATA[

    function toggleSource( id )
    {
    var elem
    var link

    if( document.getElementById )
    {
    elem = document.getElementById( id )
    link = document.getElementById( "l_" + id )
    }
    else if ( document.all )
    {
    elem = eval( "document.all." + id )
    link = eval( "document.all.l_" + id )
    }
    else
    return false;

    if( elem.style.display == "block" )
    {
    elem.style.display = "none"
    link.innerHTML = "show source"
    }
    else
    {
    elem.style.display = "block"
    link.innerHTML = "hide source"
    }
    }

    function openCode( url )
    {
    window.open( url, "SOURCE_CODE", "width=400,height=400,scrollbars=yes" )
    }
    // ]]>
  </script>
</head>
  <body>
    <ul id="menu">
      <li><a href="/thin/">about</a></li>
      <li><a href="/thin/download/">download</a></li>
      <li><a href="/thin/usage/">usage</a></li>
      <li><a href="/thin/doc/">doc</a></li>
      <li><a href="http://github.com/macournoyer/thin/">code</a></li>
      <li><a href="http://thin.lighthouseapp.com/projects/7212-thin/">bugs</a></li>
      <li><a href="/thin/users/">users</a></li>
      <li><a href="http://groups.google.com/group/thin-ruby/">community</a></li>
    </ul>
    <div id="sidebar">
      <h2>Files</h2>
      <ul class="list">
START:allfiles
        <li><a href="%root%/%href%" value="%title%">%name%</a></li>
END:allfiles
      </ul>
IF:allclasses
      
      <h2>Classes</h2>
      <ul class="list">
START:allclasses
        <li><a href="%root%/%href%" title="%title%">%name%</a></li>
END:allclasses
      </ul>
ENDIF:allclasses
    </div>
    <div id="container">
      <div id="header">
        <a href="/thin/" title="Home">
          <img id="logo" src="%root%/logo.gif" />
        </a>
        <h2 id="tag_line">A fast and very simple Ruby web server</h2>
      </div>
    
      <div id="content">
        <h2>%title%</h2>

  !INCLUDE!

      </div>
    </div>
    <div id="footer">
      <hr />
      &copy; <a href="http://macournoyer.com">Marc-Andr&eacute; Cournoyer</a>
    </div>
  </body>
</html>
}

###############################################################################

FILE_PAGE = <<_FILE_PAGE_
<div id="%full_path%" class="page_shade">
<div class="page">
<div class="header">
  <div class="path">%full_path% / %dtm_modified%</div>
</div>
#{CONTENTS_XML}
</div>
</div>
_FILE_PAGE_

###################################################################

CLASS_PAGE = %{
<div id="%full_name%" class="page_shade">
<div class="page">
IF:parent
<h3>%classmod% %full_name% &lt; HREF:par_url:parent:</h3>
ENDIF:parent
IFNOT:parent
<h3>%classmod% %full_name%</h3>
ENDIF:parent

IF:infiles
<span class="path">(in files
START:infiles
HREF:full_path_url:full_path:
END:infiles
)</span>
ENDIF:infiles
} + CONTENTS_XML + %{
</div>
</div>
}

###################################################################

METHOD_LIST = %{
IF:includes
<div class="tablesubsubtitle">Included modules</div><br>
<div class="name-list">
START:includes
  <span class="method-name">HREF:aref:name:</span>
END:includes
</div>
ENDIF:includes

IF:method_list
START:method_list
IF:methods
<table cellpadding=5 width="100%">
<tr><td class="tablesubtitle">%type% %category% methods</td></tr>
</table>
START:methods
<table width="100%" cellspacing = 0 cellpadding=5 border=0>
<tr><td class="methodtitle">
<a name="%aref%">
IF:callseq
<b>%callseq%</b>
ENDIF:callseq
IFNOT:callseq
 <b>%name%</b>%params%
ENDIF:callseq
IF:codeurl
<a href="%codeurl%" target="source" class="srclink">src</a>
ENDIF:codeurl
</a></td></tr>
</table>
IF:m_desc
<div class="description">
%m_desc%
</div>
ENDIF:m_desc
IF:aka
<div class="aka">
This method is also aliased as
START:aka
<a href="%aref%">%name%</a>
END:aka
</div>
ENDIF:aka
IF:sourcecode
<div class="sourcecode">
  <p class="source-link">[ <a href="javascript:toggleSource('%aref%_source')" id="l_%aref%_source">show source</a> ]</p>
  <div id="%aref%_source" class="dyn-source">
<pre>
%sourcecode%
</pre>
  </div>
</div>
ENDIF:sourcecode
END:methods
ENDIF:methods
END:method_list
ENDIF:method_list
}


########################## Index ################################

FR_INDEX_BODY = %{
!INCLUDE!
}

FILE_INDEX = %{
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=%charset%">
<style>
<!--
  body {
background-color: #ddddff;
     font-family: #{FONTS}; 
       font-size: 11px; 
      font-style: normal;
     line-height: 14px; 
           color: #000040;
  }
div.banner {
  background: #0000aa;
  color:      white;
  padding: 1;
  margin: 0;
  font-size: 90%;
  font-weight: bold;
  line-height: 1.1;
  text-align: center;
  width: 100%;
}
  
-->
</style>
<base target="docwin">
</head>
<body>
<div class="banner">%list_title%</div>
START:entries
<a href="%href%">%name%</a><br>
END:entries
</body></html>
}

CLASS_INDEX = FILE_INDEX
METHOD_INDEX = FILE_INDEX

INDEX = %{
<HTML>
<HEAD>
<META HTTP-EQUIV="refresh" content="0;URL=%initial_page%">
<TITLE>%realtitle%</TITLE>
</HEAD>
<BODY>
Click <a href="%initial_page%">here</a> to open the Thin docs.
</BODY>
</HTML>
}

end
end