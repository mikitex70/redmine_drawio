require 'rbpdf'

module RedmineDrawio
  module Patches
    module RbpdfPatch

      def get_image_filename(attrname)
        filename = super(attrname)
        if filename
          filename
          # rubocop:disable Lint/DuplicateBranch
        elsif %r{/attachments/download/(?<id>[^/]+)/} =~ attrname and
          atta = @attachments.find{|a| a.id.to_s == id} and
          atta.readable? and atta.visible?
          atta.diskfile
          # rubocop:enable Lint/DuplicateBranch
        elsif %r{/attachments/thumbnail/(?<id>[^/]+)/(?<size>\d+)} =~ attrname and
          atta = @attachments.find{|a| a.id.to_s == id} and
          atta.readable? and atta.visible?
          atta.thumbnail(size: size)
        else
          nil
        end
      end

    end
  end
end

Redmine::Export::PDF::ITCPDF.prepend(RedmineDrawio::Patches::RbpdfPatch)
