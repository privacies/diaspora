THIRD_PARTY_SERVICES = [:lfn].freeze
ActionController::Base.append_view_path("app/third_party_services/views")

# class StatusMessagesController
#   define_callbacks :create
#   set_callback :save, :after
# end
# 
# module Diaspora
#   module UserModules
#     module Receiving
#       define_callbacks :update_user_refs_and_add_to_aspects
#       # after_update_user_refs_and_add_to_aspects Lfn
#     end
#   end
# end
# puts "LOAD define_callbacks !"