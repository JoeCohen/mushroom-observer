# frozen_string_literal: true

require 'zip'

module ObservationReport
  # Provides rendering ability for ZIP-type reports.
  class ZipReport < ObservationReport::Base
    self.default_encoding = "UTF-8"
    self.mime_type = "text/zip"
    self.extension = "zip"
    self.header = { header: :present }

    def filename
      "test.#{extension}"
    end

    def render
      # generate a Zip from a set of steams
      debugger
      stringio = Zip::OutputStream.write_buffer do |zio|
        zip.put_next_entry("test.txt")
        zio.write("Hello world!")
      end
      stringio.string.force_encoding("UTF-8")
    end
  end
end
