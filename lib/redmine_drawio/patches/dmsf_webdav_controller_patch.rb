# frozen_string_literal: true

module RedmineDrawio
  module Patches
    ##
    # Lets the editor save a diagram to DMSF with a RedmineDrawio::ApiToken.
    #
    # The DMSF WebDAV endpoint is not a Rails controller: /dmsf/webdav is served
    # by a Rack middleware (Dav4rack) which only knows two authentication
    # schemes, HTTP Basic and Digest, and it does not consider the Rails session
    # either. Neither can be used here: the browser has no password to send and
    # the API key is not handed out to the page.
    #
    # The token is therefore accepted before the middleware gets a chance to
    # reject the request. It grants exactly the rights the user already has on
    # the document, DMSF checking them itself once User.current is set.
    module DmsfWebdavControllerPatch
      private

      # Rack::Request has no #headers, Dav4rack::Request exposes #get_header
      def drawio_token_header
        "HTTP_#{RedmineDrawio::ApiToken::HEADER.upcase.tr('-', '_')}"
      end

      def drawio_token_user
        token = request.get_header(drawio_token_header)
        user = RedmineDrawio::ApiToken.user_from_token(token)
        return false if user.nil?

        user.remote_ip = request.ip if user.respond_to?(:remote_ip=)
        User.current = user
        true
      end
    end

    ##
    # DMSF 3.x, used up to Redmine 5, enters authentication through #authenticate.
    module DmsfWebdavControllerPatchLegacy
      include DmsfWebdavControllerPatch

      def authenticate
        drawio_token_user || super
      end
    end

    ##
    # DMSF 4.x renamed #authenticate to #authenticate?.
    module DmsfWebdavControllerPatchModern
      include DmsfWebdavControllerPatch

      def authenticate?
        drawio_token_user || super
      end
    end
  end
end

# The DMSF WebDAV classes live in a plugin that is optional and may well be
# loaded after this one, hence the deferred attempt.
module RedmineDrawio
  module Patches
    class << self
      def patch_dmsf_webdav
        return false unless defined?(RedmineDmsf::Webdav::DmsfController)

        controller = RedmineDmsf::Webdav::DmsfController
        patch = if controller.method_defined?(:authenticate?) ||
                   controller.private_method_defined?(:authenticate?)
                  DmsfWebdavControllerPatchModern
                else
                  DmsfWebdavControllerPatchLegacy
                end
        return false if controller.include?(patch)

        controller.prepend(patch)
        true
      end
    end
  end
end

RedmineDrawio::Patches.patch_dmsf_webdav
Rails.application.config.to_prepare { RedmineDrawio::Patches.patch_dmsf_webdav }
