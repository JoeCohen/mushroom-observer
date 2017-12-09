module ObservationReport
  # base class
  class Base
    attr_accessor :query
    attr_accessor :encoding

    class_attribute :default_encoding
    class_attribute :mime_type
    class_attribute :extension
    class_attribute :header

    def initialize(args)
      self.query    = args[:query]
      self.encoding = args[:encoding] || default_encoding
      raise "ObservationReport initialized without query!"    unless query
      raise "ObservationReport initialized without encoding!" unless encoding
    end

    def filename
      "observations_#{query.id.alphabetize}.#{extension}"
    end

    def body
      case encoding
      when "UTF-8"
        render
      when "ASCII"
        render.to_ascii
      else
        render.iconv(encoding) # This caused problems with UTF-16 encoding.
      end
    end

    # Stub for subclasses which need to add other columns to table.
    def extend_data!(data); end

    # Stub for subclasses to sort results before formatting data.
    def sort_before(data)
      data
    end

    # Stub for subclasses to sort results after formatting data.
    def sort_after(data)
      data
    end

    def formatted_rows
      rows = all_rows.map { |row| Row.new(row) }
      rows = sort_before(rows)
      extend_data!(rows)
      sort_after(rows.map { |row| format_row(row) })
    end

    def all_rows
      rows_with_location + rows_without_location
    end

    def rows_without_location
      query.select_rows(
        select: without_location_selects.join(","),
        join: [:users, :names],
        where: "observations.location_id IS NULL",
        order: "observations.id ASC"
      )
    end

    def rows_with_location
      query.select_rows(
        select: with_location_selects.join(","),
        join: [:users, :locations, :names],
        order: "observations.id ASC"
      )
    end

    def without_location_selects
      [
        "observations.id",
        "observations.when",
        "observations.lat",
        "observations.long",
        "observations.alt",
        "observations.specimen",
        "observations.is_collection_location",
        "observations.vote_cache",
        "observations.thumb_image_id",
        "observations.notes",
        "observations.updated_at",
        "users.id",
        "users.login",
        "users.name",
        "names.id",
        "names.text_name",
        "names.author",
        "names.rank",
        '""',
        "observations.where",
        '""',
        '""',
        '""',
        '""',
        '""',
        '""'
      ]
    end

    def with_location_selects
      [
        "observations.id",
        "observations.when",
        "observations.lat",
        "observations.long",
        "observations.alt",
        "observations.specimen",
        "observations.is_collection_location",
        "observations.vote_cache",
        "observations.thumb_image_id",
        "observations.notes",
        "observations.updated_at",
        "users.id",
        "users.login",
        "users.name",
        "names.id",
        "names.text_name",
        "names.author",
        "names.rank",
        "locations.id",
        "locations.name",
        "locations.north",
        "locations.south",
        "locations.east",
        "locations.west",
        "locations.high",
        "locations.low"
      ]
    end

    # Do second query to get data from many-to-many joined table.
    def add_herbarium_labels!(rows, col)
      vals = HerbariumRecord.connection.select_rows %(
        SELECT ho.observation_id, CONCAT(h.initial_det, ": ", h.accession_number)
        FROM herbarium_records h, herbarium_records_observations ho,
              (#{query.query}) as ids
        WHERE ho.observation_id = ids.id
          AND ho.herbarium_record_id = h.id
      )
      add_column!(rows, vals, col)
    end

    def add_image_ids!(rows, col)
      vals = Image.connection.select_rows %(
        SELECT io.observation_id, io.image_id
        FROM images_observations io, (#{query.query}) as ids
        WHERE io.observation_id = ids.id
      )
      add_column!(rows, vals, col)
    end

    def add_column!(rows, vals, col)
      hash = {}
      vals.each do |id, val|
        if hash[id]
          hash[id] += ", #{val}"
        else
          hash[id] = val.to_s
        end
      end
      rows.each do |row|
        val = hash[row.obs_id] || nil
        row.add_val(val, col)
      end
    end
  end
end
