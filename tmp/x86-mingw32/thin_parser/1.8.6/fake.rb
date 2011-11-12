        class Object
          remove_const :RUBY_PLATFORM
          remove_const :RUBY_VERSION
          remove_const :RUBY_DESCRIPTION if defined?(RUBY_DESCRIPTION)
          RUBY_PLATFORM = "i386-mingw32"
          RUBY_VERSION = "1.8.6"
          RUBY_DESCRIPTION = "ruby #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) [#{RUBY_PLATFORM}]"
        end
        if RUBY_PLATFORM =~ /mswin|bccwin|mingw/
          class File
            remove_const :ALT_SEPARATOR
            ALT_SEPARATOR = "\\"
          end
        end

        posthook = proc do
          $ruby = "/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/bin/ruby"
          untrace_var(:$ruby, posthook)
        end
        trace_var(:$ruby, posthook)
