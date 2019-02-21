# see ajax_controller.rb
class AjaxController
  require "English"

  # Get EXIF header of image, return as HTML table.
  def exif
    image = Image.find(@id)
    hide_gps = image.observations.any?(&:gps_hidden)
    cmd = image.transferred ? "#{MO.root}/script/exiftool_remote" : "exiftool"
    result, status = Open3.capture2e(cmd, image.original_url);
    if status.success?
      render_exif_data(result, hide_gps)
    else
      render(plain: result, status: 500)
    end
  end

  private

  def render_exif_data(result, hide_gps)
    @data = result.split("\n").
            map { |line| [line.split(/\s*:\s+/, 2)] }.
            select { |_key, val| val != "" && val != "n/a" }.
            reject { |key, _val| hide_gps && key.match(/latitude|longitude/i) }
    render(inline: "<%= make_table(@data) %>")
  end
end
