require 'rbcurse'

module RubyCurses

  #
  # A vim-like application status bar that can display time and various other statuses
  #  at the bottom, typically above the dock (3rd line from last).
  #
  class StatusLine < Widget
    #attr_accessor :row_relative # lets only advertise this when we've tested it out

    def initialize form, config={}, &block
      @row_relative = -3
      if form.window.height == 0
        @row = Ncurses.LINES-3 # fix, what about smaller windows, use window dimensions and watch out for 0,0
      else
        @row = form.window.height-3 # fix, what about smaller windows, use window dimensions and watch out for 0,0
      end
       # in root windows FIXME
      @col = 0
      @name = "sl"
      super
      # if negativ row passed we store as relative to bottom, so we can maintain that.
      if @row < 0
        @row_relative = @row
        @row = Ncurses.LINES - @row
      else
        @row_relative = (Ncurses.LINES - @row) * -1
      end
      @focusable = false
      @editable  = false
      @command = nil
      @repaint_required = true
      bind(:PROPERTY_CHANGE) {  |e| @color_pair = nil ; }
    end
    #
    # command that returns a string that populates the status line (left aligned)
    # @see :right
    # See dbdemo.rb
    # e.g. 
    #   @l.command { "%-20s [DB: %-s | %-s ]" % [ Time.now, $current_db || "None", $current_table || "----"] }  
    #
    def command *args, &blk
      @command = blk
      @args = args
    end
    alias :left :command

    # 
    # Procudure for text to be right aligned in statusline
    def right *args, &blk
      @right_text = blk
      @right_args = args
    end

    # NOTE: I have not put a check of repaint_required, so this will print on each key-stroke OR
    #   rather whenever form.repaint is called.
    def repaint
      @color_pair ||= get_color($datacolor, @color, @bgcolor) 
      len = @form.window.getmaxx # width does not change upon resizing so useless, fix or do something
      len = Ncurses.COLS if len == 0 || len > Ncurses.COLS
      # this should only happen if there's a change in window
      if @row_relative
        @row = Ncurses.LINES+@row_relative
      end

      # first print dashes through
      @form.window.printstring @row, @col, "%s" % "-" * len, @color_pair, Ncurses::A_REVERSE

      # now call the block to get current values
      if @command
        ftext = @command.call(self, @args) 
      else
        status = $status_message ? $status_message.value : ""
        #ftext = " %-20s | %s" % [Time.now, status] # should we print a default value just in case user doesn't
        ftext = status # should we print a default value just in case user doesn't
      end
      if ftext =~ /#\[/
        @form.window.printstring_formatted @row, @col, ftext, $datacolor, Ncurses::A_REVERSE
      else
        @form.window.printstring @row, @col, ftext, $datacolor, Ncurses::A_REVERSE
      end
      # move this to formatted FIXME
      #@form.window.printstring_or_chunks @row, @col, ftext, $datacolor, Ncurses::A_REVERSE

      if @right_text
        ftext = @right_text.call(self, @right_args) 
        if ftext =~ /#\[/
          @form.window.printstring_formatted_right @row, nil, ftext, $datacolor, Ncurses::A_REVERSE
        else
          c = len - ftext.length
          @form.window.printstring @row, c, ftext, $datacolor, Ncurses::A_REVERSE
        end
      else
        t = Time.now
        tt = t.strftime "%F %H:%M:%S"
        r = Ncurses.LINES
        # 2013-03-20 - 19:04 next line printing as is in 187 ???? what to do
        ftext = "#[fg=green,bg=blue] %-20s" % [tt] # print a default
        @form.window.printstring_formatted_right @row, nil, ftext, $datacolor, Ncurses::A_REVERSE
      end

      @repaint_required = false
    end
    def handle_keys ch
      return :UNHANDLED
    end
    
  end # class
end # module
