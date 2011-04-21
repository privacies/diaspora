module ThirdPartyServicesHelper

  def ui_components_links(aspect_ids = 'all')
    aspect_ids = aspect_ids.nil? ? 'all' : aspect_ids
    # TODO Refactor and Loop inside the third party services to display, when more tps
    # Add new method to retrieve the id of the third party service
    if @third_party_service.try(:view_file) == 'lfn'
      link_to(content_tag(:span), aspects_url(:a_ids => params[:a_ids]), :class => 'lfn activated')
    else
      link_to(content_tag(:span), component_url('lfn', 'load', {:a_ids => aspect_ids}), :class => 'lfn')
    end
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