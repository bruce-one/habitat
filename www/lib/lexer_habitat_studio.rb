require 'rouge'

module Habitat
  module Lexers
    # A Rouge language lexer to allow highlighting of the right elements when
    # describing commands within the Habitat Studio.
    #
    # This lexer is essentially a copy of the Shell lexer with a few modifications
    # to use the BUILTINS regex ot match words used within the Habitat Studio.
    # @see https://github.com/jneen/rouge/blob/master/lib/rouge/lexers/shell.rb
    class HabitatStudio < Rouge::RegexLexer
      title "studio"
      desc "Habitat Studio is mostly a copy of the SHELL lexer but there are a few binaries, aliases, and functions that already exist. This removes a number of the built-ins found in "

      tag 'studio'

      KEYWORDS = %w(
        if fi else while do done for then return function
        select continue until esac elif in
      ).join('|')

      BUILTINS = %w(
        hab build sl sup-log
      ).join('|')

      state :basic do
        rule /#.*$/, Comment

        rule /\b(#{KEYWORDS})\s*\b/, Keyword
        rule /\bcase\b/, Keyword, :case

        rule /\b(#{BUILTINS})\s*\b(?!(\.|-))/, Name::Builtin
        rule /[.](?=\s)/, Name::Builtin

        rule /(\b\w+)(=)/ do |m|
          groups Name::Variable, Operator
        end

        rule /[\[\]{}()!=>]/, Operator
        rule /&&|\|\|/, Operator

        # here-string
        rule /<<</, Operator

        rule /(<<-?)(\s*)(\'?)(\\?)(\w+)(\3)/ do |m|
          groups Operator, Text, Str::Heredoc, Str::Heredoc, Name::Constant, Str::Heredoc
          @heredocstr = Regexp.escape(m[5])
          push :heredoc
        end
      end

      state :heredoc do
        rule /\n/, Str::Heredoc, :heredoc_nl
        rule /[^$\n]+/, Str::Heredoc
        mixin :interp
        rule /[$]/, Str::Heredoc
      end

      state :heredoc_nl do
        rule /\s*(\w+)\s*\n/ do |m|
          if m[1] == @heredocstr
            token Name::Constant
            pop! 2
          else
            token Str::Heredoc
          end
        end

        rule(//) { pop! }
      end


      state :double_quotes do
        # NB: "abc$" is literally the string abc$.
        # Here we prevent :interp from interpreting $" as a variable.
        rule /(?:\$#?)?"/, Str::Double, :pop!
        mixin :interp
        rule /[^"`\\$]+/, Str::Double
      end

      state :ansi_string do
        rule /\\./, Str::Escape
        rule /[^\\']+/, Str::Single
        mixin :single_quotes
      end

      state :single_quotes do
        rule /'/, Str::Single, :pop!
        rule /[^']+/, Str::Single
      end

      state :data do
        rule /\s+/, Text
        rule /\\./, Str::Escape
        rule /\$?"/, Str::Double, :double_quotes
        rule /\$'/, Str::Single, :ansi_string

        # single quotes are much easier than double quotes - we can
        # literally just scan until the next single quote.
        # POSIX: Enclosing characters in single-quotes ( '' )
        # shall preserve the literal value of each character within the
        # single-quotes. A single-quote cannot occur within single-quotes.
        rule /'/, Str::Single, :single_quotes

        rule /\*/, Keyword

        rule /;/, Punctuation

        rule /--?[\w-]+/, Name::Tag
        rule /[^=\*\s{}()$"'`;\\<]+/, Text
        rule /\d+(?= |\Z)/, Num
        rule /</, Text
        mixin :interp
      end

      state :curly do
        rule /}/, Keyword, :pop!
        rule /:-/, Keyword
        rule /[a-zA-Z0-9_]+/, Name::Variable
        rule /[^}:"`'$]+/, Punctuation
        mixin :root
      end

      state :paren do
        rule /\)/, Keyword, :pop!
        mixin :root
      end

      state :math do
        rule /\)\)/, Keyword, :pop!
        rule %r([-+*/%^|&!]|\*\*|\|\|), Operator
        rule /\d+(#\w+)?/, Num
        mixin :root
      end

      state :case do
        rule /\besac\b/, Keyword, :pop!
        rule /\|/, Punctuation
        rule /\)/, Punctuation, :case_stanza
        mixin :root
      end

      state :case_stanza do
        rule /;;/, Punctuation, :pop!
        mixin :root
      end

      state :backticks do
        rule /`/, Str::Backtick, :pop!
        mixin :root
      end

      state :interp do
        rule /\\$/, Str::Escape # line continuation
        rule /\\./, Str::Escape
        rule /\$\(\(/, Keyword, :math
        rule /\$\(/, Keyword, :paren
        rule /\${#?/, Keyword, :curly
        rule /`/, Str::Backtick, :backticks
        rule /\$#?(\w+|.)/, Name::Variable
        rule /\$[*@]/, Name::Variable
      end

      state :root do
        mixin :basic
        mixin :data
      end
    end
  end
end
