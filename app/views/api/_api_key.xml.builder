xml.tag!(tag,
  id: object.id,
  url: object.show_url,
  type: "api_key"
) do
  xml_string(xml, :key, object.key)
  xml_string(xml, :notes, object.notes)
  xml_date(xml, :joined, object.created_at)
  xml_date(xml, :verified, object.last_used)
  xml_date(xml, :integer, object.num_uses)
end
