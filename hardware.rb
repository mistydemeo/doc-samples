require 'hardware_compat'

##
# The `Hardware` module, and its classes, provide information about the
# hardware on which it is being run. This is used internally by
# Homebrew, and can also be used in formulae.
# 
# Hardware and its classes are extended with platform-specific modules,
# such as {MacCPUs}.
class Hardware

  ##
  # Provides methods to query properties of the CPU in the computer.
  # The methods defined here are default values, which are usually
  # overridden by the platform-specific modules which extend CPU.
  # For platform-specific methods, see:
  # 
  # * LinuxCPUs
  # * {MacCPUs}
  module CPU extend self

    # @return [Symbol]
    def type
      @type || :dunno
    end

    # @return [Symbol]
    def family
      @family || :dunno
    end

    # @return [Fixnum]
    def cores
      @cores || 1
    end

    # @return [Fixnum]
    def bits
      @bits || 64
    end

    # @return [Boolean]
    def is_32_bit?
      bits == 32
    end

    # @return [Boolean]
    def is_64_bit?
      bits == 64
    end
  end

  case RUBY_PLATFORM.downcase
  when /darwin/
    require 'os/mac/hardware'
    CPU.extend MacCPUs
  when /linux/
    require 'os/linux/hardware'
    CPU.extend LinuxCPUs
  else
    raise "The system `#{`uname`.chomp}' is not supported."
  end

  ##
  # Formats the number of CPU cores in an English string, suitable for
  # use in user-readable output.
  # @return [String]
  def self.cores_as_words
    case Hardware.processor_count
    when 1 then 'single'
    when 2 then 'dual'
    when 4 then 'quad'
    else
      Hardware.processor_count
    end
  end
end
