# frozen_string_literal: true

module PatternSearch
  # Parse PatternSearch parameter terms
  # Sample use:
  #   elsif term.var == :specimen
  #     args[:has_specimen] = term.parse_boolean_string
  class Term
    attr_accessor :var
    attr_accessor :vals

    def initialize(var)
      self.var = var
      self.vals = []
    end

    CONTAINS_QUOTES =
      /^("([^\"\\]+|\\.)*"|'([^\"\\]+|\\.)*'|[^\"\',]*)(\s*,\s*|$)/.freeze

    def <<(val)
      while val.to_s =~ CONTAINS_QUOTES
        vals << dequote(Regexp.last_match(1))
        val = val.to_s[Regexp.last_match(0).length..-1]
        break if val.blank?
      end
    end

    def quote(val)
      if /['" \\]/.match?(val.to_s)
        '"' + val.to_s.gsub(/(['"\\])/) { |v| '\\' + v } + '"'
      else
        val.to_s
      end
    end

    def dequote(val)
      val.to_s.sub(/^['"](.*)['"]$/, '\1').gsub(/\\(.)/, '\1')
    end

    def parse_pattern
      raise MissingValueError.new(var: var) if vals.empty?

      vals.map { |v| quote(v) }.join(" ")
    end

    def parse_boolean(only_yes = false)
      raise MissingValueError.new(var: var) if vals.empty?
      raise TooManyValuesError.new(var: var) if vals.length > 1

      val = vals.first
      return true  if /^(1|yes|true)$/i.match?(val)
      return false if /^(0|no|false)$/i.match?(val) && !only_yes
      raise BadYesError.new(var: var, val: val) if only_yes

      raise BadBooleanError.new(var: var, val: val)
    end

    def parse_yes
      parse_boolean(:only_yes) && "yes"
    end

    def parse_yes_no_both
      raise MissingValueError.new(var: var) if vals.empty?
      raise TooManyValuesError.new(var: var) if vals.length > 1

      val = vals.first
      return "only"   if /^(1|yes|true)$/i.match?(val)
      return "no"     if /^(0|no|false)$/i.match?(val)
      return "either" if /^(both|either)$/i.match?(val)

      raise BadYesNoBothError.new(var: var, val: val)
    end

    # Assure that param has only one value - a booleanish string -
    #   returning "TRUE" or "FALSE" (rather than true/false).
    # This is needed where the param interacts with user content filters and
    #   and where the relevant sql string is TRUE / FALSE
    #   e.g., :has_specimen
    def parse_to_true_false_string(only_yes = false)
      raise MissingValueError.new(var: var) if vals.empty?
      raise TooManyValuesError.new(var: var) if vals.length > 1

      val = vals.first
      return "TRUE"  if /^(1|yes|true)$/i.match?(val)
      return "FALSE" if /^(0|no|false)$/i.match?(val) && !only_yes
      raise BadYesError.new(var: var, val: val) if only_yes

      raise BadBooleanError.new(var: var, val: val)
    end

    # Assure that param has only one value - a booleanish string -
    #   returning "NULL" or "NOT NULL" (rather than true/false).
    # This is needed where the param interacts with user content filters and
    #   and where the relevant sql string is NULL / NOT NULL
    #   e.g., :has_images
    def parse_to_null_not_null_string(only_yes = false)
      raise MissingValueError.new(var: var) if vals.empty?
      raise TooManyValuesError.new(var: var) if vals.length > 1

      val = vals.first
      return "NOT NULL" if /^(1|yes|true)$/i.match?(val)
      return "NULL"     if /^(0|no|false)$/i.match?(val) && !only_yes
      raise BadYesError.new(var: var, val: val) if only_yes

      raise BadBooleanError.new(var: var, val: val)
    end

    def parse_list_of_names
      raise MissingValueError.new(var: var) if vals.empty?

      vals.map do |val|
        if /^\d+$/.match?(val)
          ::Name.safe_find(val) ||
            raise(BadNameError.new(var: var, val: val))
        else
          ::Name.find_by_text_name(val) || ::Name.find_by_search_name(val) ||
            raise(BadNameError.new(var: var, val: val))
        end
      end.map(&:id)
    end

    def parse_list_of_herbaria
      raise MissingValueError.new(var: var) if vals.empty?

      vals.map do |val|
        if /^\d+$/.match?(val)
          Herbarium.safe_find(val) ||
            raise(BadHerbariumError.new(var: var, val: val))
        else
          Herbarium.find_by_code(val) ||
            Herbarium.find_by_name(val) ||
            raise(BadHerbariumError.new(var: var, val: val))
        end
      end.map(&:id)
    end

    def parse_list_of_locations
      raise MissingValueError.new(var: var) if vals.empty?

      vals.map do |val|
        if /^\d+$/.match?(val)
          Location.safe_find(val) ||
            raise(BadLocationError.new(var: var, val: val))
        else
          Location.find_by_name(val) ||
            Location.find_by_scientific_name(val) ||
            raise(BadLocationError.new(var: var, val: val))
        end
      end.map(&:id)
    end

    def parse_list_of_projects
      raise MissingValueError.new(var: var) if vals.empty?

      vals.map do |val|
        if /^\d+$/.match?(val)
          Project.safe_find(val) ||
            raise(BadProjectError.new(var: var, val: val))
        else
          Project.find_by_title(val) ||
            raise(BadProjectError.new(var: var, val: val))
        end
      end.map(&:id)
    end

    def parse_list_of_species_lists
      raise MissingValueError.new(var: var) if vals.empty?

      vals.map do |val|
        if /^\d+$/.match?(val)
          SpeciesList.safe_find(val) ||
            raise(BadSpeciesListError.new(var: var, val: val))
        else
          SpeciesList.find_by_title(val) ||
            raise(BadSpeciesListError.new(var: var, val: val))
        end
      end.map(&:id)
    end

    def parse_list_of_users
      raise MissingValueError.new(var: var) if vals.empty?

      vals.map do |val|
        if /^\d+$/.match?(val)
          User.safe_find(val) ||
            raise(BadUserError.new(var: var, val: val))
        else
          User.find_by_login(val) ||
            User.find_by_name(val) ||
            raise(BadUserError.new(var: var, val: val))
        end
      end.map(&:id)
    end

    def parse_string
      raise MissingValueError.new(var: var) if vals.empty?
      raise TooManyValuesError.new(var: var) if vals.length > 1

      vals.first
    end

    def parse_float(min, max)
      raise MissingValueError.new(var: var) if vals.empty?
      raise TooManyValuesError.new(var: var) if vals.length > 1

      val = vals.first
      raise BadFloatError.new(var: var, val: val, min: min, max: max) \
        unless /^-?(\d+(\.\d+)?|\.\d+)$/.match?(val.to_s)
      raise BadFloatError.new(var: var, val: val, min: min, max: max) \
        unless val.to_f >= min && val.to_f <= max

      val.to_f
    end

    def parse_latitude
      parse_float(-90, 90)
    end

    def parse_longitude
      parse_float(-180, 180)
    end

    def parse_confidence
      raise MissingValueError.new(var: var) if vals.empty?
      raise TooManyValuesError.new(var: var) if vals.length > 1

      val = vals.first
      if val.to_s.match(/^-?(\d+(\.\d+)?|\.\d+)$/) &&
         (-100..100).cover?(val.to_f)
        [val.to_f * 3 / 100, 3]
      elsif val.to_s.
            match(/^(-?\d+(\.\d+)?|-?\.\d+)-(-?\d+(\.\d+)?|-?\.\d+)$/) &&
            (-100..100).cover?(Regexp.last_match(1).to_f) &&
            (-100..100).cover?(Regexp.last_match(3).to_f) &&
            Regexp.last_match(1).to_f <= Regexp.last_match(3).to_f
        [Regexp.last_match(1).to_f * 3 / 100,
         Regexp.last_match(3).to_f * 3 / 100]
      else
        raise BadConfidenceError.new(var: var, val: val)
      end
    end

    def parse_date_range
      raise MissingValueError.new(var: var) if vals.empty?
      raise TooManyValuesError.new(var: var) if vals.length > 1

      val = vals.first
      if /^(?<yr>\d{4})$/ =~ val
        yyyymmdd([yr, 1, 1], [yr, 12, 31])
      elsif /^(?<yr>\d{4})-(?<mo>\d\d?)$/ =~ val
        yyyymmdd([yr, mo, 1], [yr, mo, 31])
      elsif /^(?<yr>\d{4})-(?<mo>\d\d?)-(?<day>\d\d?)$/ =~ val
        yyyymmdd([yr, mo, day], [yr, mo, day])
      elsif /^(?<yr1>\d{4})-(?<yr2>\d{4})$/ =~ val
        yyyymmdd([yr1, 1, 1], [yr2, 12, 31])
      elsif /^(?<yr1>\d{4})-(?<mo1>\d\d?)-(?<yr2>\d{4})-(?<mo2>\d\d?)$/ =~ val
        yyyymmdd([yr1, mo1, 1], [yr2, mo2, 31])
      elsif /^(?<yr1>\d{4})-(?<mo1>\d\d?)-(?<dy1>\d\d?)-
             (?<yr2>\d{4})-(?<mo2>\d\d?)-(?<dy2>\d\d?)$/x =~ val
        yyyymmdd([yr1, mo1, dy1], [yr2, mo2, dy2])
      elsif /^(?<mo>\d\d?)$/ =~ val
        mmdd([mo, 1], [mo, 31])
      elsif /^(?<mo1>\d\d?)-(?<mo2>\d\d?)$/ =~ val
        mmdd([mo1, 1], [mo2, 31])
      elsif /^(?<mo1>\d\d?)-(?<dy1>\d\d?)-(?<mo2>\d\d?)-(?<dy2>\d\d?)$/ =~ val
        mmdd([mo1, dy1], [mo2, dy2])
      else
        raise BadDateRangeError.new(var: var, val: val)
      end
    end

    def yyyymmdd(from, to)
      [format("%04d-%02d-%02d", from.first, from.second.to_i, from.third.to_i),
       format("%04d-%02d-%02d", to.first, to.second.to_i, to.third.to_i)]
    end

    def mmdd(from, to)
      [format("%02d-%02d", from.first.to_i, from.second.to_i),
       format("%02d-%02d", to.first.to_i, to.second.to_i)]
    end

    def parse_rank_range
      raise MissingValueError.new(var: var) if vals.empty?
      raise TooManyValuesError.new(var: var) if vals.length > 1

      val = vals.first
      from, to = val.split("-", 2).map(&:strip)
      to ||= from
      from = lookup_rank(from)
      to   = lookup_rank(to)
      raise BadRankRangeError.new(var: var, val: val) if from.nil? || to.nil?

      from == to ? [from] : [from, to]
    end

    def lookup_rank(val)
      val = val.downcase
      ::Name.all_ranks.each do |rank|
        if val == rank.to_s.downcase ||
           val == :"rank_#{rank.to_s.downcase}".l || alt_rank_check(rank, val)
          return rank
        end
      end
      nil
    end

    def alt_rank_check(rank, val)
      if [:Phylum, :Group].include?(rank)
        ranks = :"rank_alt_#{rank.to_s.downcase}".l.split(",")
        ranks.map(&:strip).include?(val)
      else
        false
      end
    end
  end
end
