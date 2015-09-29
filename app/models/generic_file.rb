class GenericFile < Resource
  include Sufia::GenericFile
  include StillImageMetadata
  include TextMetadata
  include AssetMetadata

  def self.aic_type
    super << AICType.Asset
  end

  type aic_type

  def is_still_image?
    self.type.include? AICType.StillImage
  end

  def is_text?
    self.type.include? AICType.Text
  end

  def assert_still_image
    return true if is_still_image?
    return false if is_text?
    t = self.get_values(:type)
    t << AICType.StillImage
    self.set_value(:type, t)
  end

  def assert_text
    return true if is_text?
    return false if is_still_image?
    t = self.get_values(:type)
    t << AICType.Text
    self.set_value(:type, t)
  end

  def prefix
    return "TX" if is_text?
    return "SI" if is_still_image?
    raise ArgumentError, "Can't assign a prefix without a type"
  end

  def self.indexer
    ::AssetIndexer
  end

  private

    # Overrides Sufia::Noid#service
    def service
      @service ||= UidMinter.new(prefix)
    end

end
