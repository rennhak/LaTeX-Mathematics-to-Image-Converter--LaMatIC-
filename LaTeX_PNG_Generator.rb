#!/usr/bin/ruby
#

# == OptionParser related
require 'optparse'
require 'ostruct'


# Runs only on Linux w/ Ruby, LaTeX, convert

# In the web you could use e.g. http://hausheer.osola.com/latex2png

class SnippetGenerator # {{{

  def initialize options = nil # {{{
    @options = options

    # Minimal configuration
    @config                       = OpenStruct.new
    @config.tmp_dir               = "tmp"
    @config.png_dir               = "pngs"
    @config.default_fn            = "formula"

    unless( options.nil? )
      clean         if( @options.clean )

      # ugly quickhack
      unless( @options.latex.empty? )

        @options.latex.each_with_index do |formula, index|
          clean
          texify formula, index
        end

      end # of unless( @options.latex.empty? )

    end # of unless( options.nil? )

  end # of def initialize }}}

  def clean # {{{
    # create tmp dir in local folder
    `rm -rf #{@config.tmp_dir}` unless( Dir[ @config.tmp_dir ].empty? )
    Dir.mkdir( @config.tmp_dir )

    puts "Do you want to delete the folder ./#{@config.png_dir} ?"
    `rm -rfI #{@config.png_dir}`
    Dir.mkdir( @config.png_dir )
  end # }}}

  def texify formula, index # {{{

    template_start  = "\\documentclass[30pt]{article}\n\\pagestyle{empty}\n\\begin{document}\n\\begin{displaymath}\n"
    template_stop   = "\\end{displaymath}\n\\end{document}"

    Dir.chdir( @config.tmp_dir ) do |d|

      tex_filename = "#{@config.default_fn}_#{index.to_s}.tex"

      # Generate TeX file
      File.open( tex_filename, "w" ) do |f|
        f.write template_start
        f.write formula.to_s
        f.write "\n"
        f.write template_stop
      end # of File


      `texi2dvi #{tex_filename}`
      `dvips -E #{tex_filename.gsub( ".tex", ".dvi" ) }`
      `convert -density 400x400 #{tex_filename.gsub( ".tex", ".ps" )} #{tex_filename.gsub( ".tex", ".png" )}`

    end # of Dir.
  end # }}}

  # = The function 'parse_cmd_arguments' takes a number of arbitrary commandline arguments and parses them into a proper data structure via optparse
  # @param args Ruby's STDIN.ARGS from commandline
  # @returns Ruby optparse package options hash object
  def parse_cmd_arguments( args ) # {{{

    args_copy                         = args.dup
    options                           = OpenStruct.new

    # Define default options
    options.latex                     = []

    pristine_options                  = options.dup!

    opts                              = OptionParser.new do |opts|
      opts.banner                     = "Usage: #{__FILE__.to_s} [options]"

      opts.separator ""
      opts.separator "General options:"

      opts.on("-g", "--generate-png-from-latex OPT", "Generate PNG file from LaTeX input OPT" ) do |d|
        options.latex << d
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end

      # Another typical switch to print the version.
      opts.on_tail("--version", "Show version") do
        puts OptionParser::Version.join('.')
        exit
      end
    end

    opts.parse!(args)

    # Show opts if we have no cmd arguments
    if( args_copy.empty? )
      puts opts
      puts ""
      STDERR.puts "You need to define at least -g. e.g. #{__FILE__} -g \"\\sigma = \\alpha + \\beta\"'\n\n"
      exit
    end

    options
  end # of parse_cmd_arguments }}}

end # of SnippetGenerator }}}


# = Direct invocation, for manual testing beside rspec
if __FILE__ == $0 # {{{

  options  = SnippetGenerator.new.parse_cmd_arguments( ARGV )
  sg       = SnippetGenerator.new( options )

end # }}}

# vim=ts:2
