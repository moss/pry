require 'ostruct'
class Pry::Config
  DEFAULT_STATE = {
    :input                  => proc { Readline },
    :output                 => proc { $stdout },
    :commands               => proc { Pry::Commands },
    :prompt_name            => proc { Pry::DEFAULT_PROMPT_NAME },
    :prompt                 => proc { Pry::DEFAULT_PROMPT },
    :prompt_safe_objects    => proc { Pry::DEFAULT_PROMPT_SAFE_OBJECTS },
    :print                  => proc { Pry::DEFAULT_PRINT },
    :quiet                  => proc { Pry.quiet },
    :exception_handler      => proc { Pry::DEFAULT_EXCEPTION_HANDLER },
    :exception_whitelist    => proc { Pry::DEFAULT_EXCEPTION_WHITELIST },
    :hooks                  => proc { Pry::DEFAULT_HOOKS },
    :pager                  => proc { true },
    :system                 => proc { Pry::DEFAULT_SYSTEM },
    :color                  => proc { Pry::Helpers::BaseHelpers.use_ansi_codes? },
    :default_window_size    => proc { 5 },
    :editor                 => proc { Pry.default_editor_for_platform }, # TODO: Pry::Platform.editor
    :should_load_rc         => proc { true },
    :should_load_local_rc   => proc { true },
    :should_trap_interrupts => proc { Pry::Helpers::BaseHelpers.jruby? }, # TODO: Pry::Platform.jruby?
    :disable_auto_reload    => proc { false },
    :command_prefix         => proc { "" },
    :auto_indent            => proc { Pry::Helpers::BaseHelpers.use_ansi_codes? },
    :correct_indent         => proc { true },
    :collision_warning      => proc { true },
    :output_prefix          => proc { "=> "},
    :requires               => proc { [] },
    :should_load_requires   => proc { true },
    :should_load_plugins    => proc { true },
    :control_d_handler      => proc { Pry::DEFAULT_CONTROL_D_HANDLER },
    :memory_size            => proc { 100 },
    :extra_sticky_locals    => proc { {} },
    :completer              => proc {
      if defined?(Bond) && Readline::VERSION !~ /editline/i
        Pry::BondCompleter.start
      else
        Pry::InputCompleter.start
      end
    }
  }.freeze
  attr_accessor *DEFAULT_STATE.keys
  attr_reader :lookup
  alias :quiet? :quiet


  def initialize(options = {})
    @lookup = DEFAULT_STATE.dup
    @lookup.merge!(options)
    configure_gist
    configure_history
    configure_ls
  end

  def [](key)
    @lookup[key]
  end

  def []=(key, value)
    @lookup[key] = value
  end

  def method_missing(name, *args, &block)
    if @lookup.key?(name)
      @lookup[name]
    elsif name.to_s.end_with?("=")
      name = name.to_s[0..-2].to_sym
      @lookup[name] = args.at(0)
    else
      super
    end
  end

  def merge!(other)
    other.respond_to?(:lookup) ? @lookup.merge(other.lookup) : @lookup.merge(other)
  end

  # FIXME: This is a hack to alert people of the new API.
  # @param [Pry::Hooks] v Only accept `Pry::Hooks` now!
  def hooks=(v)
    if v.is_a?(Hash)
      warn "Hash-based hooks are now deprecated! Use a `Pry::Hooks` object instead! http://rubydoc.info/github/pry/pry/master/Pry/Hooks"
      @hooks = Pry::Hooks.from_hash(v)
    else
      @hooks = v
    end
  end

private
  def configure_ls
    # TODO: configure in the ls command.
    self.ls = OpenStruct.new({
      :heading_color            => :bright_blue,
      :public_method_color      => :default,
      :private_method_color     => :blue,
      :protected_method_color   => :blue,
      :method_missing_color     => :bright_red,
      :local_var_color          => :yellow,
      :pry_var_color            => :default,     # e.g. _, _pry_, _file_
      :instance_var_color       => :blue,        # e.g. @foo
      :class_var_color          => :bright_blue, # e.g. @@foo
      :global_var_color         => :default,     # e.g. $CODERAY_DEBUG, $eventmachine_library
      :builtin_global_color     => :cyan,        # e.g. $stdin, $-w, $PID
      :pseudo_global_color      => :cyan,        # e.g. $~, $1..$9, $LAST_MATCH_INFO
      :constant_color           => :default,     # e.g. VERSION, ARGF
      :class_constant_color     => :blue,        # e.g. Object, Kernel
      :exception_constant_color => :magenta,     # e.g. Exception, RuntimeError
      :unloaded_constant_color  => :yellow,      # Any constant that is still in .autoload? state
      :separator                => "  ",
      :ceiling                  => [Object, Module, Class]
    })
  end

  def configure_gist
    # TODO: configure in gist command.
    self.gist = OpenStruct.new
    gist.inspecter = proc(&:pretty_inspect)
  end

  def configure_history
    self.history ||= OpenStruct.new
    history.should_save = true
    history.should_load = true
    history.file = File.expand_path("~/.pry_history") rescue nil
    if history.file.nil?
      self.should_load_rc = false
      history.should_save = false
      history.should_load = false
    end
  end
end
