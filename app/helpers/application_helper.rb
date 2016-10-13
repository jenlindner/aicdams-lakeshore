# frozen_string_literal: true
module ApplicationHelper
  def resource_type_facets
    @resource_types.reject { |r| r.is_a?(Integer) }.sort
  end

  def render_documents(presenter)
    return unless presenter.document_presenters.present?
    render 'relationship', rel_term: "Documentation", rel_term_asset: "Documentation For", presenters: presenter.document_presenters
  end

  def render_representations(presenter)
    return unless presenter.representation_presenters.present?
    render 'relationship', rel_term: "Representations", rel_term_asset: "Representation Of", presenters: presenter.representation_presenters
  end

  def render_preferred_representations(presenter)
    return unless presenter.preferred_representation_presenters.present?
    render 'relationship', rel_term: "Preferred Representation", rel_term_asset: "Preferred Representation Of", presenters: presenter.preferred_representation_presenters
  end

  def link_to_citi(model, citi_uid)
    citi_tbl_ids = {
      Work: 3,
      Agent: 54,
      Place: 7,
      Exhibition: 151,
      Transaction: 167,
      Shipment: 180
    }
    citi_tbl_id = citi_tbl_ids[model.to_sym]
    link_to "View this #{model} in CITI", "http://citiworker10.artic.edu:8080/edit/?tableID=" + citi_tbl_id.to_s + "&uid=" + citi_uid.to_s, target: "_blank", class: "btn btn-default citi-btn"
  end

  def link_to_human_readable_date(options)
    value = options[:value].first

    label = Date.parse(value).to_formatted_s(:standard)
    solr_format_date = Date.parse(value).strftime("%F")
    #2012-09-24T00:00:00Z TO 2012-09-24T23:59:99.999Z
    #2016-10-12T*:*:*Z TO 2016-10-12T*:*:*.999Z
    #[2016-10-12/DAY TO 2016-10-12/DAY+1DAY]
    solr_date_search = "#{solr_format_date}"
    link_to(label, main_app.search_catalog_path(f: { 'date_modified_dttsi' => ["#{value}"]}))
  end

end
