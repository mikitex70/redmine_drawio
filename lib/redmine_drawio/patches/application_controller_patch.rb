# frozen_string_literal: true

module RedmineDrawio
  module Patches
    ##
    # Lets a browser call the Redmine REST API with a RedmineDrawio::ApiToken
    # instead of the API key of the current user, which is never exposed to the
    # client.
    #
    # The token is accepted only in the places where the API key would have been
    # accepted (Redmine REST API enabled, API formatted request, action open to
    # API authentication), so it grants exactly the rights of the API key of the
    # user it was issued to.
    module ApplicationControllerPatch
      def find_current_user
        super || drawio_api_token_user
      end

      private

      def drawio_api_token_user
        return nil unless Setting.rest_api_enabled?
        return nil unless api_request? && accept_api_auth?

        user = RedmineDrawio::ApiToken.authenticate(request)
        user.remote_ip = request.remote_ip if user

        user
      end
    end
  end
end

ApplicationController.prepend RedmineDrawio::Patches::ApplicationControllerPatch