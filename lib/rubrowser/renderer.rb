require 'erb'
require 'yaml'
require 'rubrowser/data'
require 'rubrowser/formatter/json'

module Rubrowser
  class Renderer
    # Accepted options are:
    # files: list of file paths to parse
    # toolbox: bool, show/hide toolbox
    def self.call(options = {})
      new(options).call
    end

    def call
      output.write(erb(:index))
    end

    private

    include ERB::Util

    attr_reader :files, :output, :server, :config

    def initialize(options)
      @output = output_file(options[:output])
      @layout = options[:layout]
      @server = options[:server]
      @files = options[:files]
      @toolbox = options[:toolbox]
      @config = options[:config] ? YAML.load_file(options[:config]) : {}
    end

    def output_file(path)
      path.is_a?(String) ? File.open(path, 'w') : path
    end

    def layout
      return 'null' unless @config['layout'] || @layout
      if @config['layout']
        @config['layout'].to_json
      else
        File.read(@layout)
      end
    end

    def groups
      return 'null' unless @config['groups']
      @config['groups'].to_json
    end

    def toolbox_config(arg)
      ((@config['toolbox_config'] || {})[arg] || '').gsub(/\s+/, "\n")
    end

    def toolbox?
      @toolbox
    end

    def data
      data = Data.new(files)
      formatter = Formatter::JSON.new(data)
      formatter.call
    end

    def file(path)
      File.read(resolve_file_path("/public/#{path}"))
    end

    def erb(template)
      path = resolve_file_path("/views/#{template}.erb")
      file = File.open(path).read
      ERB.new(file).result binding
    end

    def resolve_file_path(path)
      File.expand_path("../../..#{path}", __FILE__)
    end
  end
end
