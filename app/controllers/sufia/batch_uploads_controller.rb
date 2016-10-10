# frozen_string_literal: true
class Sufia::BatchUploadsController < ApplicationController
  include Sufia::BatchUploadsControllerBehavior

  def self.form_class
    BatchUploadForm
  end

  def create_update_job
    attributes = []
    attributes << attributes_for_actor
    attributes << params[:dept_created]

    log = Sufia::BatchCreateOperation.create!(user: current_user,
                                              operation_type: "Batch Create")
    ::BatchAssetCreateJob.perform_later(current_user,
                                        params[:pref_label],
                                        params[:uploaded_files],
                                        attributes,
                                        log)
  end
end
