#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

module AspectsHelper
  def link_for_aspect( aspect )
    link_to aspect.name, aspect
  end

  def remove_link( aspect )
    if aspect.contacts.size == 0
      link_to I18n.t('aspects.helper.remove'), aspect, :method => :delete, :confirm => I18n.t('aspects.helper.are_you_sure')
    else
      "<span class='grey' title=#{I18n.t('aspects.helper.aspect_not_empty')}>#{I18n.t('aspects.helper.remove')}</span>"
    end
  end

  def add_to_aspect_button(aspect_id, person_id)
    link_to image_tag('icons/monotone_plus_add_round.png'),
      {:controller => "aspects",
        :action => 'add_to_aspect',
        :aspect_id => aspect_id,
        :person_id => person_id},
      :remote => true,
      :class => 'add button'
  end

  def remove_from_aspect_button(aspect_id, person_id)
    link_to image_tag('icons/monotone_check_yes.png'),
      {:controller => "aspects",
        :action => 'remove_from_aspect',
        :aspect_id => aspect_id,
        :person_id => person_id},
      :remote => true,
      :class => 'added button'
  end

  def aspect_membership_button(aspect_id, contact, person)
    if contact.nil? || !contact.aspect_ids.include?(aspect_id)
      add_to_aspect_button(aspect_id, person.id)
    else
      remove_from_aspect_button(aspect_id, person.id)
    end
  end
  
  def get_aspect_contacts(aspect_id)
    
    if (aspect_id == "all")
      target_aspects=current_user.aspects.collect{|x| x.id}
    else
      target_aspects=[aspect_id]
    end
    
    target_contacts = Contact.all(:aspect_ids.in => target_aspects, :pending => false)
    
    target_handles = target_contacts.collect do |contact|
      contact.person.diaspora_handle
    end
  end
  
end

