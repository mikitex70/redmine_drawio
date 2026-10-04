# frozen_string_literal: true

require 'active_support/message_verifier'
require 'digest'

module RedmineDrawio
  ##
  # Short lived credential embedded in the pages where a diagram can be edited.
  #
  # To save a diagram the browser has to call the Redmine REST API (upload the
  # attachment and rewrite the wiki page or the issue), and the REST API only
  # accepts the API key of the current user. Handing the API key over to the
  # page is not an option: everybody able to read the page source could reuse
  # it, forever, from anywhere.
  #
  # So the page gets a token instead. It is signed with a server only key, so it
  # cannot be forged or tampered with, it carries nothing but the id of the user
  # it belongs to and it is refused once expired. The REST API key never leaves
  # the server. ApplicationControllerPatch accepts the token where the API key
  # would have been accepted, granting exactly the same rights.
  module ApiToken
    HEADER = 'X-Redmine-Drawio-Token'
    PURPOSE = 'redmine_drawio'
    # Long enough to edit a diagram from a page left open for a while, short
    # enough to bound the exposure of a leaked token (view source, browser
    # extension, shared screenshot of the page source, ...).
    TTL = 15.minutes

    module_function

    ##
    # Token to be embedded in the page of the given user.
    # Returns an empty string when no token must be issued.
    #
    # The anonymous user gets a token too: the page is only rendered where a
    # diagram can be edited, so the token grants nothing the visitor does not
    # already have, and it does not expose the api key of the anonymous user.
    def issue(user)
      return '' if user.nil? || two_factor_pending?(user)

      verifier.generate(payload(user), expires_in: TTL)
    end

    ##
    # User matching the token carried by the request, nil when the header is
    # missing, malformed, expired or refers to a user which is no longer active.
    def authenticate(request)
      user_from_token(request.headers[HEADER])
    end

    ##
    # User matching the given token, nil when it is missing, malformed, expired
    # or refers to a user which is no longer active.
    #
    # Callers authenticating a request that is not a Rails controller (the DMSF
    # WebDAV endpoint, which lives in a Rack middleware) read the header
    # themselves and hand the token over.
    def user_from_token(token)
      return nil if token.blank?

      user = user_from(verifier.verify(token.to_s))
      two_factor_pending?(user) ? nil : user
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end

    def payload(user)
      "#{PURPOSE}:#{user.id}"
    end

    def user_from(payload)
      id = payload[/\A#{Regexp.escape(PURPOSE)}:(\d+)\z/, 1]
      return nil if id.nil?

      User.active.find_by_id(id)
    end

    # A plain string is signed, never deserialized, so no payload format and no
    # serializer is involved here.
    def verifier
      ActiveSupport::MessageVerifier.new(secret)
    end

    def secret
      @secret ||= Digest::SHA256.hexdigest("#{Rails.application.secret_key_base}#{PURPOSE}")
    end

    # A token must never be a way around a pending two factor authentication.
    def two_factor_pending?(user)
      !user.nil? && user.respond_to?(:must_activate_twofa?) && user.must_activate_twofa?
    end
  end
end