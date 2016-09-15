# frozen_string_literal: true
module AssetType
  class Image < Base
    def self.all
      ["application/pdf",
       "image/jpeg",
       "image/png",
       "image/tiff",
       "image/vnd.adobe.photoshop"]
    end
  end
end