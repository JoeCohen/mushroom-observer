class IpStats
  class << self
    def log_stats(stats)
      file = MO.ip_stats_file
      now = Time.current
      File.open(file, "a") do |fh|
        fh.puts [
          now,
          stats[:ip],
          User.current_id,
          now - stats[:time],
          stats[:controller],
          stats[:action]
        ].join(",")
      end
    end

    def read_stats
      data = {}
      now = Time.current
      read_file(MO.ip_stats_file) do |time, ip, user, load, controller, action|
        hash = data[ip] ||= { load: 0, activity: [], rate: 0 }
        # Weight turns rate into average number of requests per second,
        # and load into average server time used per minute.  It weights the
        # most recent minute 10x more heavily than the minute before cutoff.
        weight = (600 - (now - Time.parse(time))) / 600 / 600 * 2
        hash[:user] = user.to_i if user.present?
        hash[:load] += load.to_f * weight
        hash[:rate] += weight
        hash[:activity] << [time, load.to_f, controller, action]
      end
      data
    end

    def clean_stats
      cutoff = (Time.current - 10.minutes).to_s
      rewrite_ip_stats { |time| time > cutoff }
    end

    def blocked?(ip)
      populate_blocked_ips unless blocked_ips_current?
      @@blocked_ips.include?(ip)
    end

    def blocked_ips
      populate_blocked_ips unless blocked_ips_current?
      @@blocked_ips
    end

    def add_blocked_ips(ips)
      file = MO.blocked_ips_file
      File.open(file, "a") do |fh|
        ips.each do |ip|
          fh.puts "#{ip},#{Time.current}"
        end
      end
    end

    def remove_blocked_ips(ips)
      rewrite_blocked_ips { |ip, time| !ips.include?(ip) }
    end

    def clean_blocked_ips
      cutoff = (Time.current - 1.day).to_s
      rewrite_blocked_ips { |ip, time| time > cutoff }
    end

    def reset!
      # Force reload next time used.
      @@blocked_ips_time = nil
    end

    private

    def blocked_ips_current?
      defined?(@@blocked_ips_time) &&
        @@blocked_ips_time.present? &&
        @@blocked_ips_time >= File.mtime(MO.blocked_ips_file) &&
        @@blocked_ips_time >= File.mtime(MO.okay_ips_file)
    end

    def populate_blocked_ips
      file1 = MO.blocked_ips_file
      file2 = MO.okay_ips_file
      @@blocked_ips = parse_ip_list(file1) - parse_ip_list(file2)
      @@blocked_ips_time = [File.mtime(file1), File.mtime(file2)].max
    end

    def parse_ip_list(file)
      FileUtils.touch(file) unless File.exist?(file)
      File.open(file).readlines.map do |line|
        line.chomp.split(",").first
      end
    end

    def rewrite_blocked_ips(&block)
      rewrite_file(MO.blocked_ips_file, &block)
    end

    def rewrite_ip_stats(&block)
      rewrite_file(MO.ip_stats_file, &block)
    end

    def read_file(file)
      File.open(file, "r") do |fh|
        fh.each_line do |line|
          yield(*line.chomp.split(","))
        end
      end
    end

    def rewrite_file(file1)
      file2 = "#{file1}.#{Process.pid}"
      File.open(file1, "r") do |fh1|
        File.open(file2, "w") do |fh2|
          fh1.each_line do |line|
            fh2.write(line) if yield(*line.chomp.split(","))
          end
        end
      end
      File.delete(file1)
      File.rename(file2, file1)
    end
  end
end
