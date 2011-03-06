class UserInterfaceComponent

  EMPTY_VALUE = 'none'

  #Preload all ui components
  def self.load_components(force_reload = false)
    @@components = UI_COMPONENTS.each_with_object({}) do |c, h|
      h[c] = Object.const_get(c.to_s.classify) if Object.const_get(c.to_s.classify)
    end
  end

  def self.get(component)
    self.load_components
    return @@components[component.to_sym] if @@components[component.to_sym]
    nil
  end

  def self.get_aspect_contacts(aspect_id, user)
    if (aspect_id == "all")
      target_aspects = user.aspects.collect{|x| x.id}
    elsif aspect_id.is_a? Array
      target_aspects = aspect_id
    else
      target_aspects = [aspect_id]
    end

    target_contacts = Contact.joins(:aspect_memberships).where(:aspect_memberships => {:aspect_id => target_aspects}, :pending => false)

    return EMPTY_VALUE if target_contacts.empty?
    target_contacts.collect do |contact|
      contact.person.diaspora_handle
    end
  end

  def self.get_aspect_contacts_from_ids(aspect_ids, user)
    aspect_ids.map do |id|
      get_aspect_contacts(id, user)
    end.reject {|v| v == EMPTY_VALUE }
  end

  def self.run(action, params = {})
    self.load_components
    @@components.each_value do |c|
      c::send(action, params) if c::respond_to?(action)
    end
  end

  def view_file
    self.class.downcase
  end

end
