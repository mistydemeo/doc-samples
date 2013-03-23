require 'hardware_compat'

class Hardware
  ##
  # = Hardware
  # 
  # The +Hardware+ module, and its classes, provide information about the
  # hardware on which it is being run. This is used internally by
  # Homebrew, and can also be used in formulae.
  # 
  # Hardware and its classes are extended with platform-specific modules,
  # such as MacCPUs.

  module CPU extend self
    ##
    # Provides methods to query properties of the CPU in the computer.
    def type
      @type || :dunno
    end

    def family
      @family || :dunno
    end

    def cores
      @cores || 1
    end

    def bits
      @bits || 64
    end

    def is_32_bit?
      bits == 32
    end

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
  # Returns a string representing the number of CPU cores in English,
  # suitable for use in user-readable output.
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
