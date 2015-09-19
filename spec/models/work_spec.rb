require 'rails_helper'

describe Work do

  describe "intial RDF types" do
    subject { described_class.new.type }
    it { is_expected.to contain_exactly(AICType.Work, AICType.CitiResource, AICType.Resource) }
  end

  describe "metadata" do
    subject { described_class.new }
    context "defined in the presenter" do
      WorkPresenter.terms.each do |term|
        it { is_expected.to respond_to(term) }
      end
    end
  end

  describe "#assets" do
    let(:asset) do
      GenericFile.create.tap do |f|
        f.title = ["Asset in a work"]
        f.apply_depositor_metadata "user"
        f.save
      end
    end
    let(:work) do
      Work.create.tap do |w|
        w.asset_ids = [asset.id]
        w.save
      end
    end
    specify { expect(work.assets).to include(asset) }
    context "when removing the asset from the work" do
      before { work.asset_ids = [] }
      it "retains the asset" do
        expect(work.assets).to be_empty
        expect(GenericFile.all).to include(asset)
      end
    end
    context "when deleting the asset" do
      before { asset.destroy }
      it "removes the asset from the work" do
        pending
        expect(work.assets).to be_empty
      end
    end
  end

  describe "#representations and #preferred_representations" do
    let(:representation) do
      GenericFile.create.tap do |f|
        f.title = ["Representation of a work"]
        f.apply_depositor_metadata "user"
        f.save
      end
    end
    let(:work) do
      Work.create.tap do |w|
        w.representation_ids = [representation.id]
        w.preferred_representation_ids = [representation.id]
        w.save
      end
    end
    specify { expect(work.representations).to include(representation) }
    specify { expect(work.preferred_representations).to include(representation) }
    context "when removing the representation from the work" do
      before do
        work.representation_ids = []
        work.save
      end
      it "retains the preferred representation" do
        expect(work.representations).to be_empty
        expect(work.preferred_representations).to include(representation)
      end
    end
  end

  describe "#to_solr" do
    subject { described_class.new.to_solr }
    it "has default public read access" do
      expect(subject["read_access_group_ssim"]).to include("public")
    end
    it "has an AIC type" do
      expect(subject["aic_type_sim"]).to include("Work")
    end
  end

  describe "visibility" do
    specify { expect(described_class.visibility).to eql "open" }
  end

  describe "permissions" do
    subject { described_class.new } 
    it { is_expected.to be_public }
    it { is_expected.not_to be_registered }
  end

  context "with CITI resources" do
    before { load_fedora_fixture(fedora_fixture("work.ttl")) }
    it "indexes them into solr" do
      expect(Work.all.count).to eql 1
    end

  end

end
