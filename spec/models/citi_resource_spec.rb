# frozen_string_literal: true
require 'rails_helper'

describe CitiResource do
  describe "RDF type" do
    subject { described_class.new.type }
    it { is_expected.to contain_exactly(AICType.Resource, AICType.CitiResource) }
  end

  describe "terms" do
    CitiResourceTerms.all.each do |term|
      it { is_expected.to respond_to(term) }
    end
  end

  describe "#citi_uid" do
    subject { described_class.properties["citi_uid"] }
    it { is_expected.not_to be_multiple }
  end

  describe "#status" do
    subject { described_class.new.status }
    it { is_expected.to eq(StatusType.active) }
  end

  describe "::find_by_citi_uid" do
    let!(:resource) { described_class.create(citi_uid: "AB-1234") }
    subject { described_class.find_by_citi_uid(id) }
    context "with an exact search" do
      let(:id) { "AB-1234" }
      its(:citi_uid) { is_expected.to eq(id) }
    end
    context "with a fuzzy search" do
      let(:id) { "AB-1" }
      it { is_expected.to be_nil }
    end
    context "with a nil id" do
      let(:id) { nil }
      it { is_expected.to be_nil }
    end
  end

  describe "with events" do
    subject { described_class.new }
    its(:events) { is_expected.to be_empty }
  end

  context "with an implementation" do
    before do
      class SampleCitiResource < CitiResource
        include ::CurationConcerns::WorkBehavior
        include CitiBehaviors
      end
    end

    after do
      Object.send(:remove_const, :SampleCitiResource) if defined?(SampleCitiResource)
    end

    subject { SampleCitiResource.new }

    describe "Hydra ACLs" do
      before { SampleCitiResource.create(pref_label: "Sample CITI Resource") }
      specify "are not created for the resource" do
        expect(Permissions::Writable::AccessControl.all.count).to eq(0)
      end
    end

    describe "#to_solr" do
      let(:solr_doc) { subject.to_solr }
      it "has default public read access" do
        expect(solr_doc["read_access_group_ssim"]).to contain_exactly("group", "registered")
      end
      it "has an AIC type" do
        expect(solr_doc["aic_type_sim"]).to include("SampleCitiResource")
      end
      it "has a status" do
        expect(solr_doc[Solrizer.solr_name("status", :symbol)]).to eq(["Active"])
      end
    end

    describe "visibility" do
      specify { expect(SampleCitiResource.visibility).to eql "authenticated" }
    end

    describe "permissions" do
      it { is_expected.not_to be_department }
      it { is_expected.to be_registered }
    end

    describe "#edit_groups" do
      its(:edit_groups) { is_expected.to include("registered") }
    end

    describe "featureability" do
      specify { expect(SampleCitiResource.new).not_to be_featureable }
    end

    describe "assigning representations" do
      let(:resource)                   { SampleCitiResource.new }
      let(:asset)                      { create(:asset) }
      let(:solr_representations)       { asset.to_solr[Solrizer.solr_name("representation", :facetable)] }
      let(:facets_for_representations) { facets_for(Solrizer.solr_name("representation", :facetable), asset.id) }

      before do
        resource.representations = [asset]
        resource.preferred_representation = asset
        resource.documents = [asset]
        resource.save
      end
      it "contains the correct kind of representations" do
        expect(resource.representations).to include(asset)
        expect(resource.preferred_representation).to eq(asset)
        expect(resource.documents).to include(asset)
        expect(solr_representations).to contain_exactly("Is Document", "Is Representation", "Is Preferred Representation")
        expect(facets_for_representations).to contain_exactly("Is Document", 1, "Is Representation", 1, "Is Preferred Representation", 1)
      end
      context "when removing the representation from the resource" do
        before do
          resource.representations = []
          resource.save
        end
        it "retains the preferred representation" do
          expect(resource.representations).to be_empty
          expect(resource.preferred_representation).to eq(asset)
          expect(solr_representations).to contain_exactly("Is Document", "Is Preferred Representation")
          expect(facets_for_representations).to contain_exactly("Is Document", 1, "Is Preferred Representation", 1)
        end
      end
      context "when removing the asset" do
        before { asset.destroy }
        specify do
          expect(asset.errors).to include(:representations)
          expect(asset).to be_persisted
        end
      end
      context "when reloading as a solr document" do
        let(:solr_doc) { SolrDocument.new(resource.to_solr, nil) }
        subject { solr_doc.to_model }
        its(:preferred_representation) { is_expected.to eq(asset) }
      end
    end
  end
end
