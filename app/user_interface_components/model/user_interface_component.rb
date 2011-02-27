class UserInterfaceComponent
  @@components = {}
  @@callbacks  = {}

  #Preload all ui components
  def self.load_components(force_reload = false)
    @@components = UI_COMPONENTS.each_with_object({}) do |c, h|
      h[c] = Object.const_get(c.to_s.classify).new if Object.const_get(c.to_s.classify)
    end
  end

  #get the ui component
  def self.get(component)
    self.load_components
    return @@components[component.to_sym] if @@components[component.to_sym]
    nil
  end

  def self.get_aspect_contacts(aspect_id, user)
    if (aspect_id == "all")
      target_aspects = user.aspects.collect{|x| x.id}
    else
      target_aspects = [aspect_id]
    end

    target_contacts = Contact.joins(:aspect_memberships).where(:aspect_memberships => {:aspect_id => target_aspects}, :pending => false)

    target_handles = target_contacts.collect do |contact|
      contact.person.diaspora_handle
    end
  end

  def self.set_callback(method)
    
  end
  
  def self.run_callback
    
  end

  def link
    ""
  end

  def view_file
    self.class.downcase
  end
end
