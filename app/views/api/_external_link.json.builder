json.id            object.id
json.id            "external_link"
json.url           object.url
json.external_site object.site_name
json.created_at    object.created_at
json.updated_at    object.updated_at
if !detail
  json.owner_id       object.user_id
  json.observation_id object.observation_id
else
  json.owner       json_detailed_object(json, object.user)
  json.observation json_detailed_object(json, object.observation)
end
