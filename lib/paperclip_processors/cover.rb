module Paperclip
  
  class CoverThumb < Processor
    
    def initialize(file, options = {})
      super
      @file             = file
      @whiny            = options[:whiny].nil? ? true : options[:whiny]
      @current_format   = File.extname(@file.path)
      @basename         = File.basename(@file.path, @current_format)
      @overlay          = RAILS_ROOT + "/public/images/release_overlay.png" 
    end  
    
    def make
      dst = Tempfile.new([@basename, @format].compact.join("."))
      command = "-gravity center " + @overlay + " " + File.expand_path(@file.path) + " " +File.expand_path(dst.path)
      dst.binmode
      begin
        success = Paperclip.run("composite", command.gsub(/\s+/, " "))
      rescue PaperclipCommandLineError
        raise PaperclipError, "There was an error processing the overlay. CMD = #{command}" if @whiny
      end
      dst
    end
  
  end
    
  class CoverCanvasOriginal < Processor
    
    def initialize(file, options = {})
      super
      @file             = file
      @whiny            = options[:whiny].nil? ? true : options[:whiny]
      @current_format   = File.extname(@file.path)
      @basename         = File.basename(@file.path, @current_format)
      @canvas          = RAILS_ROOT + "/public/images/white_canvas_original.png" 
    end
    
    def make
      dst = Tempfile.new([@basename, @format].compact.join("."))
      command = "-gravity center " + File.expand_path(@file.path) + " " + @canvas + " " +File.expand_path(dst.path)
      dst.binmode
      begin
        success = Paperclip.run("composite", command.gsub(/\s+/, " "))
      rescue PaperclipCommandLineError
        raise PaperclipError, "There was an error processing the overlay. CMD = #{command}" if @whiny
      end
      dst
    end

  end

  class CoverWatermarkOriginal < Processor
    
    def initialize(file, options = {})
      super
      @file             = file
      @whiny            = options[:whiny].nil? ? true : options[:whiny]
      @current_format   = File.extname(@file.path)
      @basename         = File.basename(@file.path, @current_format)
      @overlay          = RAILS_ROOT + "/public/images/watermark_original.png" 
    end
    
    def make
      dst = Tempfile.new([@basename, @format].compact.join("."))
      command = "-gravity south " + @overlay + " " + File.expand_path(@file.path) + " " +File.expand_path(dst.path)
      dst.binmode
      begin
        success = Paperclip.run("composite", command.gsub(/\s+/, " "))
      rescue PaperclipCommandLineError
        raise PaperclipError, "There was an error processing the overlay. CMD = #{command}" if @whiny
      end
      dst
    end

end

  class CoverCanvasNormal < Processor
    
    def initialize(file, options = {})
      super
      @file             = file
      @whiny            = options[:whiny].nil? ? true : options[:whiny]
      @current_format   = File.extname(@file.path)
      @basename         = File.basename(@file.path, @current_format)
      @canvas          = RAILS_ROOT + "/public/images/white_canvas_normal.png" 
    end
    
    def make
      dst = Tempfile.new([@basename, @format].compact.join("."))
      command = "-gravity center " + File.expand_path(@file.path) + " " + @canvas + " " +File.expand_path(dst.path)
      dst.binmode
      begin
        success = Paperclip.run("composite", command.gsub(/\s+/, " "))
      rescue PaperclipCommandLineError
        raise PaperclipError, "There was an error processing the overlay. CMD = #{command}" if @whiny
      end
      dst
    end

  end

  class CoverWatermarkNormal < Processor
    
    def initialize(file, options = {})
      super
      @file             = file
      @whiny            = options[:whiny].nil? ? true : options[:whiny]
      @current_format   = File.extname(@file.path)
      @basename         = File.basename(@file.path, @current_format)
      @overlay          = RAILS_ROOT + "/public/images/watermark_normal.png" 
    end
    
    def make
      dst = Tempfile.new([@basename, @format].compact.join("."))
      command = "-gravity south " + @overlay + " " + File.expand_path(@file.path) + " " +File.expand_path(dst.path)
      dst.binmode
      begin
        success = Paperclip.run("composite", command.gsub(/\s+/, " "))
      rescue PaperclipCommandLineError
        raise PaperclipError, "There was an error processing the overlay. CMD = #{command}" if @whiny
      end
      dst
    end

  end

end