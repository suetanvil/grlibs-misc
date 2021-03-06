#!/usr/bin/env ruby

# Simplified version of gd_resize.rb that resizes one image.
require 'pry'  # DEBUG! REMOVE!
require 'rubygems'

require 'optparse'

require 'gd2-ffij'
include GD2

# Add path to local modules
proc {
  $LOAD_PATH.unshift(File.dirname(__FILE__))
}.call()


MODES = {
#  'default'             => GD_DEFAULT,
  'bell'                => GD_BELL,
  'bessel'              => GD_BESSEL,
  'bilinear_fixed'      => GD_BILINEAR_FIXED,
  'bicubic'             => GD_BICUBIC,
  'bicubic_fixed'       => GD_BICUBIC_FIXED,
  'blackman'            => GD_BLACKMAN,
  'box'                 => GD_BOX,
  'bspline'             => GD_BSPLINE,
  'catmullrom'          => GD_CATMULLROM,
  'gaussian'            => GD_GAUSSIAN,
  'generalized_cubic'   => GD_GENERALIZED_CUBIC,
  'hermite'             => GD_HERMITE,
  'hamming'             => GD_HAMMING,
  'hanning'             => GD_HANNING,
  'mitchell'            => GD_MITCHELL,
  'nearest_neighbour'   => GD_NEAREST_NEIGHBOUR,
  'power'               => GD_POWER,
  'quadratic'           => GD_QUADRATIC,
  'sinc'                => GD_SINC,
  'triangle'            => GD_TRIANGLE,
#  'weighted4'           => GD_WEIGHTED4,
}



def shrink(imgfile, width, height, output, truecolor, modeName, blur, sharpenPct)
  mode = MODES[modeName]
  raise "Invalid mode '#{modeName}'." unless mode

  im = Image.import(imgfile)

  # Force input object to truecolor if needed.
  if truecolor && !im.true_color?
    im = im.to_true_color()
  end

  # Blur the image if requested
  if blur
    im.gaussian_blur!
  end

  # Zero or invalid height means preserve aspect ratio
  height = ( (im.height * width.to_f) / im.width ).round if height <= 0

  im.interpolation_method = mode
  raise "Unable to set interpolation mode." unless 
    mode == im.interpolation_method

  raise "Invalid dimension: #{width}x#{height}" unless
    width > 0 && height > 0
  
  result = im.resizeInterpolated(width, height)

  if sharpenPct > 0
    result.sharpen(sharpenPct)
  end

  opts = {}
  case File.extname(output).downcase.to_sym
  when :jpg, :jpeg
    opts[:quality] = 100
    
    # ... more goes here, maybe ...
  end

  moveOldFile(output)
  result.save_alpha = true  # this is off by default
  result.export(output, opts)
end



# Rename file 'name' to something different and (probably) unique
def moveOldFile(name)
  return unless File.file?(name)

  count = 0
  while true
    count += 1
    nfn = "#{name}.#{count}"

    if !File.file?(nfn)
      File.rename(name, nfn)
      break
    end
  end
end



def main
  truecolor = false
  mode = 'bicubic'
  blur = false
  sharpenPct = 0

  OptionParser.new do |opts|
    opts.banner =
      "Usage: #{__FILE__} <ifile> <width> [<height>|'-'] <ofile>..."


    opts.on('--force-truecolor', "Force input images to truecolor.") {
      truecolor = true
    }

    opts.on('--interp MODE', '--mode MODE', 
            "Use interpolation mode 'MODE'.") { |im|
      raise "Unknown interpolation mode '#{im}'" unless MODES.has_key?(im)
      mode = im
    }

    opts.on('--modes', "List all interpolation modes and exit.") {
      print MODES.keys.sort.join("\n"), "\n"
      exit 0
    }

    opts.on('--blur', "Pre-filter image with a gaussian blur.") { |im|
      blur = true
    }

    opts.on('--sharpen PERCENT', Float, "Sharpen the resulting image.") { |im|
      sharpenPct = im.round
      if sharpenPct <= 0
        puts "Invalid sharpen percentage: #{sharpenPct}"
        exit 1
      end
    }
  end.parse!

  if ARGV.size != 4
    puts "USAGE: resize <input> <width> <height> <output>"
    exit 1
  end

  w = ARGV[1].to_i
  if w == 0
    puts "Invalid width: #{w}"
    exit 1
  end

  h = ARGV[2].to_i      # <= 0 means compute from width

  shrink ARGV[0], w, h, ARGV[3], truecolor, mode, blur, sharpenPct
end


main()

