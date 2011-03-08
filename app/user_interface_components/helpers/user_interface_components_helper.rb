module UserInterfaceComponentsHelper
  def ui_components_links(aspect_id = 'all')
    aspect_id = aspect_id.nil? ? 'all' : aspect_id
    link_to "Lfn", component_url('lfn', 'load', {:aspect_id => aspect_id, :user => current_user})
  end
  
  def component_url(ui_component, action, params = {})
    uic_path(Lfn::url_params(params).merge({:ui_component => ui_component, :action => action}))
  end
  
end