class ThirdPartyService

  require 'rexml/document'

  include AESCrypt
  include REXML

  @@components = {}

  #Preload all ui components
  def self.load_components(force_reload = false)
    @@components = THIRD_PARTY_SERVICES.each_with_object({}) do |c, h|
      h[c] = Object.const_get(c.to_s.classify) if Object.const_get(c.to_s.classify)
    end
  end

  # return the component if exists
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

    return nil if target_contacts.empty?
    target_contacts.collect do |contact|
      contact.person.diaspora_handle
    end
  end

  def self.get_aspect_contacts_from_ids(aspect_ids, user)
    aspect_ids.map do |id|
      get_aspect_contacts(id, user)
    end.compact.uniq
  end

  # TODO instead of this maybe use ActiveSupport::Notifications
  def self.run(action, params = {})
    self.load_components
    @@components.each_value do |c|
      c::send(action, params) if c::respond_to?(action)
    end
  end

  # return the view file to render / by default the view file is the name of the class downcase
  def self.view_file
    self.to_s.downcase
  end

  def self.invoke(params = {})
    @service_url = params[:service_url]
    @method      = params[:method]
    #TODO to refactor
    @params      = params[:params].reject {|k, v| v.blank? }.map {|k, v| {"params[#{k}]" => Base64.encode64(AESCrypt.encrypt(v, AppConfig[:encryption_key], AppConfig[:iv], "AES-256-CBC"))}}

    Rails.logger.info("Invoke : service_url=#{@service_url} method=#{@method} #{@params}")

    # TODO change the verb
    response = Net::HTTP.post_form(URI.parse(@service_url), {:method => @method}.merge(@params))

    doc = Document.new(response.body)
    doc.each_element('//Column') { |column| column.text = AESCrypt.decrypt(Base64.decode64(column.text, AppConfig[:encryption_key], AppConfig[:iv], "AES-256-CBC")) }
    doc.to_s
  end

end