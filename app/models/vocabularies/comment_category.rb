# frozen_string_literal: true
class CommentCategory < BaseVocabulary
  def self.query
    List.find_by_label("Comment Category")
  end
end
