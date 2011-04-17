module ThirdPartyServicesHelper

  def ui_components_links(aspect_id = nil)
    link_to(image_tag('third_party_services/icons/lfn.png', :alt => "Lfn", :title => "Lfn"),
            component_url('lfn', 'load', {:aspect_id => aspect_id, :user => current_user}))
  end

  def component_url(service_name, action, params = {})
    tps_path(Lfn::url_params(params).merge({:service_name => service_name, :action => action}))
  end

  def json_aspect_contacts
    current_user.aspect_ids.each_with_object({}) do |a_id, h|
      h[a_id] = ThirdPartyService::get_aspect_contacts_from_ids(a_id)
    end.to_json
  end

end