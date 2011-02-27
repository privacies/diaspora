module Diaspora
  module UserModules
    module Receiving
      define_callbacks :update_user_refs_and_add_to_aspects
      # after_update_user_refs_and_add_to_aspects Lfn
    end
  end
end
puts "LOAD define_callbacks !"