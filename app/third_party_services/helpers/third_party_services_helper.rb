module ThirdPartyServicesHelper

  def ui_components_links(aspect_ids = 'all')
    aspect_ids = aspect_ids.nil? ? 'all' : aspect_ids
    link_to(image_tag('third_party_services/icons/lfn.png', :alt => "Lfn", :title => "Lfn"),
            component_url('lfn', 'load', {:aspect_ids => aspect_ids}))
  end

  def component_url(service_name, action, params = {})
    tps_path(params.merge({:service_name => service_name, :action => action}))
  end

  def json_aspect_contacts(aspect_ids = nil, in_hash = true)
    aspect_ids = current_user.aspect_ids unless aspect_ids
    aspect_contacts = aspect_ids.each_with_object({}) do |a_id, h|
      h[a_id] = ThirdPartyService::get_aspect_contacts_from_ids(a_id)
    end
    return aspect_contacts.values.flatten.compact.uniq.to_json if in_hash == false
    aspect_contacts.to_json
  end

end