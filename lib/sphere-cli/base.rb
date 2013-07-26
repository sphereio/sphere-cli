module Sphere

  module CommandBase

    def sphere
      # Initialized in pre-hook
      return $sphere_client_instance
    end

    def folder
      # Initialized in pre-hook
      return $sphere_folder_instance
    end

    def code
      # Initialized in pre-hook
      return $sphere_code_instance
    end

    def download
      # Initialized in pre-hook
      return $sphere_download_instance
    end

    def slugify(name)
      name.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
    end

    # prints the specified text to output, unless running in quiet mode
    def printMsg(text)
      $stderr.puts text unless $quiet
    end

    # prints the specified text to output as a status line, unless running in quiet mode
    # status line resets the current line and does not print newline at the end
    def printStatusLine(text="")
      return if $quiet
      # move cursor to beginning of line
      cr = "\r"
      # ANSI escape code to clear line from cursor to end of line
      # "\e" is an alternative to "\033"
      # cf. http://en.wikipedia.org/wiki/ANSI_escape_code
      clear = "\e[0K"
      # reset lines
      resetLine = cr + clear
      $stderr.print "#{resetLine}#{text}"
    end

    def pluralize(n, singular, plural=nil, omit_number = false)
      if n == 1
        "#{"1 " unless omit_number}#{singular}"
      elsif plural
        "#{"#{n} " unless omit_number}#{plural}"
      else
        "#{"#{n} " unless omit_number}#{singular}s"
      end
    end

    def lang_val(value)
      language = 'en'
      return value[language] if value.class == Hash
      { language.to_sym => value }
    end

    # Obtain a value from the specified JSON object following a path of
    # attribute names (i.e. go deeper into each attribute) specified in attribPath
    # (an array of strings).
    # The attribPath can also contain path item defined as "[xxx=yyy/zzz]" in which case
    # it would assume the next level is a JSON array and it will find the first member
    # of the array whose attribute xxx has value yyy (if any) and follow it's zzz attribute.
    # If the path cannot be resolved (attributes or array elements not found),
    # return the optional valueIfNotFound string (empty string by default)
    def jsonValue(item, attribPath, valueIfNotFound = "")
      value = item
      attribPath.each do |attrName|
        return valueIfNotFound if !value
        if attrName =~ /^\[(.*)=(.*)\/(.*)\]$/
          found=false
          value.each do |arrVal|
            if (arrVal[$1]==$2)
              value = arrVal[$3]
              found=true
              break
            end
          end
          return valueIfNotFound if !found
        else
          value = value[attrName]
        end
      end
      return value.to_s
    end

    def ask
      $stdin.gets.to_s.strip
    end

    def askToContinue (defaultYes=true)
      # special cases for forcing and quiet flags
      return true if $force
      return true if $quiet && defaultYes
      if (defaultYes)
        print "Do you want to continue [Y/n]? "
        cont = ask
        return false if cont.downcase == 'n'
      else
        print "Do you want to continue [y/N]? "
        cont = ask
        return false if cont.downcase != 'y'
      end
      return true
    end

    def echo_off
      with_tty do
        system "stty -echo"
      end
    end

    def echo_on
      with_tty do
        system "stty echo"
      end
    end

    def with_tty(&block)
      return unless $stdin.isatty
      yield
    end

    def ask_for_password_on_windows
      require "Win32API"
      char = nil
      password = ''

      while char = Win32API.new("crtdll", "_getch", [ ], "L").Call do
        break if char == 10 || char == 13 # received carriage return or newline
        if char == 127 || char == 8 # backspace and delete
          password.slice!(-1, 1)
        else
          # windows might throw a -1 at us so make sure to handle RangeError
          (password << char.chr) rescue RangeError
        end
      end
      puts
      return password
    end

    def ask_for_password
      echo_off
      password = ask
      puts
      echo_on
      return password
    end

    def running_on_windows?
      RUBY_PLATFORM =~ /mswin32|mingw32/
    end

    def running_on_a_mac?
      RUBY_PLATFORM =~ /-darwin\d/
    end

    # a standard way of outputting JSON data received from the server based on global options
    def performJSONOutput(options, json)
      if (options[:"json-pretty"])
        # if we ask for pretty JSON, parse and prettify
        data = parse_JSON json
        puts JSON.pretty_generate(data)
      elsif (options[:"json-raw"] || !block_given?)
        # if we ask for raw data output or no block for operating on the data is given, print the data
        puts json
      else
        # in all other cases parse and pass the data to the provided block
        yield parse_JSON json
      end
    end

    def get_project_key(input, get_from_folder = true)
      key = nil;
      if input.class == Array
        key = input[0]
      elsif input.class == Hash
        key = input[:project]
      end
      key ||= folder.project_key if get_from_folder
      raise 'No project key provided.' if key.to_s.empty?
      key
    end

    def validate_input_as_JSON args
      input = get_input args
      # parse the input to be sure it's valid JSON, but return raw data
      parse_JSON input
      return input
    end

    def get_input args, message = 'No arguments provided.'
      raise message if args.empty?
      input = args[0]
      if input =~  /^@/
        file = input[1, input.length] # remove the @ before the file name
        input = get_file_input file
      end
      return input
    end

    def get_file_input filename, message = 'No filename provided.'
      if filename.class == Array
        raise message if filename.empty?
        filename = filename[0]
      end
      raise "File '#{filename}' does not exist." unless File.file? filename
      File.read filename
    end

    def parse_JSON data
      begin
        return JSON.parse data
      rescue JSON::ParserError => e
        raise "Can't parse JSON: #{e}"
      end
    end
  end

end
