##
# Provides methods to query properties of the CPU in the computer.
# This module's methods will be mixed into `Hardware::CPU` on MacOS X.
# 
# Several of these methods use info spewed out by sysctl.
# Look in `<mach/machine.h>` for decoding info.

module MacCPUs
  OPTIMIZATION_FLAGS = {
    :penryn => '-march=core2 -msse4.1',
    :core2 => '-march=core2',
    :core => '-march=prescott',
    :g3 => '-mcpu=750',
    :g4 => '-mcpu=7400',
    :g4e => '-mcpu=7450',
    :g5 => '-mcpu=970'
  }
  ##
  # Returns a hash containing optimization flags suitable for the
  # hardware being used. The keys are in the same format as `CPU.family`.
  # @return [Hash]
  def optimization_flags; OPTIMIZATION_FLAGS.dup; end

  ##
  # @return [Symbol] :intel or :ppc
  def type
    @type ||= `/usr/sbin/sysctl -n hw.cputype`.to_i
    case @type
    when 7
      :intel
    when 18
      :ppc
    else
      :dunno
    end
  end

  ##
  # Queries the family of CPU being used. Values are symbols, suitable
  # for use with the `optimization_flags` hash.
  # If the CPU family isn't recognized but is of a recognized CPU type,
  # returns :dunno. Otherwise returns nil.
  # @return [Symbol, nil]
  def family
    if type == :intel
      @intel_family ||= `/usr/sbin/sysctl -n hw.cpufamily`.to_i
      case @intel_family
      when 0x73d67300 # Yonah: Core Solo/Duo
        :core
      when 0x426f69ef # Merom: Core 2 Duo
        :core2
      when 0x78ea4fbc # Penryn
        :penryn
      when 0x6b5a4cd2 # Nehalem
        :nehalem
      when 0x573B5EEC # Arrandale
        :arrandale
      when 0x5490B78C # Sandy Bridge
        :sandybridge
      when 0x1F65E835 # Ivy Bridge
        :ivybridge
      else
        :dunno
      end
    elsif type == :ppc
      @ppc_family ||= `/usr/sbin/sysctl -n hw.cpusubtype`.to_i
      case @ppc_family
      when 9
        :g3  # PowerPC 750
      when 10
        :g4  # PowerPC 7400
      when 11
        :g4e # PowerPC 7450
      when 100
        :g5  # PowerPC 970
      else
        :dunno
      end
    end
  end

  ##
  # @return [Fixnum] the number of CPU cores available
  def cores
    @cores ||= `/usr/sbin/sysctl -n hw.ncpu`.to_i
  end

  ##
  # @return [Fixnum]
  def bits
    return @bits if defined? @bits

    is_64_bit = sysctl_bool("hw.cpu64bit_capable")
    @bits ||= is_64_bit ? 64 : 32
  end

  ##
  # Checks for availability of the AltiVec instruction set.
  # This will be true on PowerPC processors G4 and newer.
  # @return [Boolean]
  def altivec?
    type == :ppc && family != :g3
  end

  ##
  # Checks for availability of the SSE3 instruction set.
  # This will be true on all supported Intel processors.
  # @return [Boolean]
  def sse3?
    type == :intel
  end

  ##
  # Checks for availability of the SSE4 instruction set.
  # This will be true on Intel processors newer than Core 2.
  # @return [Boolean]
  def sse4?
    type == :intel && (family != :core && family != :core2)
  end

  protected

  ##
  # Queries the `sysctl` kernel state tool for a boolean value.
  # @return [true] a boolean representing the sysctl value
  def sysctl_bool(property)
    result = nil
    IO.popen("/usr/sbin/sysctl -n #{property} 2>/dev/null") do |f|
      result = f.gets.to_i # should be 0 or 1
    end
    $?.success? && result == 1 # sysctl call succeded and printed 1
  end
end
