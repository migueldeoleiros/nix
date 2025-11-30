{config, pkgs, inputs, vars, ...}:

let
  palette = {
    background= "#090a11";
    background-alt= "#13141B";
    background-attention= "#242532";
    border= "#090a11";
    current-line= "#404159";
    selection= "#404159";
    foreground= "#D4DAE8";
    foreground-alt= "#AFB4C0";
    foreground-attention= "#ffffff";
    comment= "#7BA3F4";
    cyan= "#51BACD";
    green= "#57B272";
    orange= "#E68E5C";
    pink= "#EA75CB";
    purple= "#9F71EA";
    red= "#D1526D";
    yellow= "#DDC16E";
  };   
in 
{
  programs.qutebrowser = {
    enable = true;
    loadAutoconfig = true;

    searchEngines = {
      DEFAULT = "https://search.brave.com/search?q={}";
      w = "https://en.wikipedia.org/wiki/Special:Search?search={}&go=Go&ns0=1";
      aw = "https://wiki.archlinux.org/?search={}";
      nw = "https://nixos.wiki/index.php?search={}";
      np = "https://search.nixos.org/packages?query={}";
      ddg = "https://duckduckgo.com/?q={}";
      g = "https://www.google.com/search?hl=en&q={}";
    };

    keyBindings = {
      normal = {
        #tabs
        "<Ctrl+1>"= "tab-focus 1";
        "<Ctrl+2>"= "tab-focus 2";
        "<Ctrl+3>"= "tab-focus 3";
        "<Ctrl+4>"= "tab-focus 4";
        "<Ctrl+5>"= "tab-focus 5";
        "<Ctrl+6>"= "tab-focus 6";
        "<Ctrl+7>"= "tab-focus 7";
        "<Ctrl+8>"= "tab-focus 8";
        "<Ctrl+9>"= "tab-focus 9";
        "<Shift+j>"= "tab-prev";
        "<Shift+k>"= "tab-next";
        
        #download an image
        "I"= "hint images download";
        
        #mpv/vlc video
        "M"= "hint links spawn mpv {hint-url}";
        #"M"= "hint links spawn vlc {hint-url}";
        
        #togle bars
        "xx"= "config-cycle statusbar.show always never;; config-cycle tabs.show always never";
      };
    };

    extraConfig = "c.tabs.padding = {'top': 5, 'bottom': 7, 'right': 6, 'left': 8}
c.statusbar.padding = {'top': 5, 'bottom': 7, 'right': 6, 'left': 8}";

    settings = {

      url.default_page = "file:///home/${vars.user}/.config/qutebrowser/homepage/homepage.html"; 
      url.start_pages = "file:///home/${vars.user}/.config/qutebrowser/homepage/homepage.html"; 

      #adblock
      content.blocking = {
        method = "both"; 
        adblock.lists = ["https://easylist.to/easylist/easylist.txt"
                         "https://easylist.to/easylist/easyprivacy.txt"
                         "https://easylist-downloads.adblockplus.org/antiadblockfilters.txt"];
      };

      fonts.default_family = "Source pro";
      fonts.default_size = "10.5pt";

      tabs = {
        indicator.width = 1;
        favicons.scale = 1;
      };

      hints.border = "1px solid ${palette.background-alt}";

      colors = {
        webpage = {
          #darkmode
          bg = palette.background;
          darkmode.enabled = false;
          darkmode.threshold.background = 100;
          darkmode.threshold.foreground = 256 - 100;
          darkmode.policy.images = "never";
          preferred_color_scheme = "dark";
        };

        completion = {
          ## Background color of the completion widget category headers.
          category.bg = palette.background; 

          ## Bottom border color of the completion widget category headers.
          category.border.bottom = palette.border;
          
          ## Top border color of the completion widget category headers.
          category.border.top = palette.border;
          
          ## Foreground color of completion widget category headers.
          category.fg = palette.foreground;
          
          ## Background color of the completion widget for even rows.
          even.bg = palette.background;
          
          ## Background color of the completion widget for odd rows.
          odd.bg = palette.background-alt;
          
          ## Text color of the completion widget.
          fg = palette.foreground;
          
          ## Background color of the selected completion item.
          item.selected.bg = palette.selection;
          
          ## Bottom border color of the selected completion item.
          item.selected.border.bottom = palette.selection;
          
          ## Top border color of the completion widget category headers.
          item.selected.border.top = palette.selection;
          
          ## Foreground color of the selected completion item.
          item.selected.fg = palette.foreground;
          
          ## Foreground color of the matched text in the completion.
          match.fg = palette.orange;
          
          ## Color of the scrollbar in completion view
          scrollbar.bg = palette.background;
          
          ## Color of the scrollbar handle in completion view.
          scrollbar.fg = palette.foreground;
        };

        
        downloads = {
          ## Background color for the download bar.
          bar.bg = palette.background;

          ## Background color for downloads with errors.
          error.bg = palette.background;
        
          ## Foreground color for downloads with errors.
          error.fg = palette.red;
          
          ## Color gradient stop for download backgrounds.
          stop.bg = palette.background;
          
          ## Color gradient interpolation system for download backgrounds.
          ## Type: ColorSystem
          ## Valid values:
          ##   - rgb: Interpolate in the RGB color system.
          ##   - hsv: Interpolate in the HSV color system.
          ##   - hsl: Interpolate in the HSL color system.
          ##   - none: Don't show a gradient.
          system.bg = "none";
        };
        

        hints = {
          ## Background color for hints. Note that you can use a `rgba(...)` value
          ## for transparency.
          bg = palette.background;

          ## Font color for hints.
          fg = palette.purple;

          ## Font color for the matched part of hints.
          match.fg = palette.foreground-alt;
        };
        
        keyhint = {
          ## Background color of the keyhint widget.
          bg = palette.background; 

          ## Text color for the keyhint widget.
          fg = palette.purple;

          ## Highlight color for keys to complete the current keychain.
          suffix.fg = palette.selection;
        };

        messages = {
          ## Background color of an error message.
          error.bg = palette.background; 

          ## Border color of an error message.
          error.border = palette.background-alt;
          
          ## Foreground color of an error message.
          error.fg = palette.red;
          
          ## Background color of an info message.
          info.bg = palette.background;
          
          ## Border color of an info message.
          info.border = palette.background-alt;
          
          ## Foreground color an info message.
          info.fg = palette.comment;
          
          ## Background color of a warning message.
          warning.bg = palette.background;
          
          ## Border color of a warning message.
          warning.border = palette.background-alt;
          
          ## Foreground color a warning message.
          warning.fg = palette.red;
        };
        
        prompts = {
          ## Background color for prompts.
          bg = palette.background;
        
          # ## Border used around UI elements in prompts.
          #border = '1px solid ' + palette['background-alt'];
        
          ## Foreground color for prompts.
          fg = palette.cyan;
          
          ## Background color for the selected item in filename prompts.
          selected.bg = palette.selection;
        };

        statusbar = {
          ## Background color of the statusbar in caret mode.
          caret.bg = palette.background;

          ## Foreground color of the statusbar in caret mode.
          caret.fg = palette.orange;
        
          ## Background color of the statusbar in caret mode with a selection.
          caret.selection.bg = palette.background;
          
          ## Foreground color of the statusbar in caret mode with a selection.
          caret.selection.fg = palette.orange;
          
          ## Background color of the statusbar in command mode.
          command.bg = palette.background;
          
          ## Foreground color of the statusbar in command mode.
          command.fg = palette.pink;
          
          ## Background color of the statusbar in private browsing + command mode.
          command.private.bg = palette.background;
          
          ## Foreground color of the statusbar in private browsing + command mode.
          command.private.fg = palette.foreground-alt;
          
          ## Background color of the statusbar in insert mode.
          insert.bg = palette.background-attention;
          
          ## Foreground color of the statusbar in insert mode.
          insert.fg = palette.foreground-attention;
          
          ## Background color of the statusbar.
          normal.bg = palette.background;
          
          ## Foreground color of the statusbar.
          normal.fg = palette.foreground;
          
          ## Background color of the statusbar in passthrough mode.
          passthrough.bg = palette.background;
          
          ## Foreground color of the statusbar in passthrough mode.
          passthrough.fg = palette.orange;
          
          ## Background color of the statusbar in private browsing mode.
          private.bg = palette.background-alt;
          
          ## Foreground color of the statusbar in private browsing mode.
          private.fg = palette.foreground-alt;
          
          ## Background color of the progress bar.
          progress.bg = palette.background;
          
          ## Foreground color of the URL in the statusbar on error.
          url.error.fg = palette.red;
          
          ## Default foreground color of the URL in the statusbar.
          url.fg = palette.foreground;
          
          ## Foreground color of the URL in the statusbar for hovered links.
          url.hover.fg = palette.cyan;
          
          ## Foreground color of the URL in the statusbar on successful load
          url.success.http.fg = palette.green;
          
          ## Foreground color of the URL in the statusbar on successful load
          url.success.https.fg = palette.green;
          
          ## Foreground color of the URL in the statusbar when there's a warning.
          url.warn.fg = palette.yellow;
        };
        
        tabs = {
          ## Background color of the tab bar.
          ## Type: QtColor
          bar.bg = palette.background-attention;

          ## Background color of unselected even tabs.
          ## Type: QtColor
          even.bg = palette.background-attention;
          
          ## Foreground color of unselected even tabs.
          ## Type: QtColor
          even.fg = palette.foreground;
          
          ## Color for the tab indicator on errors.
          ## Type: QtColor
          indicator.error = palette.red;
          
          ## Color gradient start for the tab indicator.
          ## Type: QtColor
          indicator.start = palette.orange;
          
          ## Color gradient end for the tab indicator.
          ## Type: QtColor
          indicator.stop = palette.green;
          
          ## Color gradient interpolation system for the tab indicator.
          ## Type: ColorSystem
          ## Valid values:
          ##   - rgb: Interpolate in the RGB color system.
          ##   - hsv: Interpolate in the HSV color system.
          ##   - hsl: Interpolate in the HSL color system.
          ##   - none: Don't show a gradient.
          indicator.system = "none";
          
          ## Background color of unselected odd tabs.
          ## Type: QtColor
          odd.bg = palette.background-attention;
          
          ## Foreground color of unselected odd tabs.
          ## Type: QtColor
          odd.fg = palette.foreground;
          
          # ## Background color of selected even tabs.
          # ## Type: QtColor
          selected.even.bg = palette.background;
          
          # ## Foreground color of selected even tabs.
          # ## Type: QtColor
          selected.even.fg = palette.foreground;
          
          # ## Background color of selected odd tabs.
          # ## Type: QtColor
          selected.odd.bg = palette.background;
          
          # ## Foreground color of selected odd tabs.
          # ## Type: QtColor
          selected.odd.fg = palette.foreground;
        };
      };
    };
  };
}
