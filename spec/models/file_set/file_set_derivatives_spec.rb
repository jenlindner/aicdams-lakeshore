# frozen_string_literal: true
require 'rails_helper'

describe FileSet do
  let(:file)        { build(:department_file, id: '1234') }
  let(:derivatives) { CurationConcerns::DerivativePath.derivatives_for_reference(file) }

  before { LakeshoreTesting.reset_derivatives }

  describe "#create_derivatives" do
    context "with image mime types" do
      let(:image_file) { File.join(fixture_path, "tardis.png") }

      let(:outputs) do
        [
          {
            label:  :thumbnail,
            format: "jpg",
            size:   "200x150>",
            url:    "file:#{Rails.root}/tmp/test/derivatives/12/34-thumbnail.jpeg"
          },
          {
            label:  :access,
            format: "jp2[512x512]",
            url:    "file:#{Rails.root}/tmp/test/derivatives/12/34-access.jp2"
          }
        ]
      end

      before { allow(file).to receive(:mime_type).and_return("image/png") }

      it "sends the correct parameters for J2K files" do
        expect(Hydra::Derivatives::ImageDerivatives).to receive(:create).with(image_file, outputs: outputs)
        file.create_derivatives(image_file)
      end

      describe "the derivatives", skip: LakeshoreTesting.continuous_integration? do
        subject { derivatives }
        before  { file.create_derivatives(image_file) }
        it { is_expected.to contain_exactly(end_with("34-access.jp2"), end_with("34-thumbnail.jpeg")) }
      end
    end

    context "with pdf types" do
      let(:pdf_file) { File.join(fixture_path, "test.pdf") }

      let(:outputs) do
        [
          {
            label:  :thumbnail,
            format: "jpg",
            size:   "200x150>",
            url:    "file:#{Rails.root}/tmp/test/derivatives/12/34-thumbnail.jpeg"
          }
        ]
      end

      let(:extraction) do
        [{ url: kind_of(RDF::URI), container: "extracted_text" }]
      end

      before { allow(file).to receive(:mime_type).and_return("application/pdf") }

      it "sends the correct parameters for pdf files" do
        expect(Hydra::Derivatives::PdfDerivatives).to receive(:create).with(pdf_file, outputs: outputs)
        expect(Hydra::Derivatives::FullTextExtract).to receive(:create).with(pdf_file, outputs: extraction)
        file.create_derivatives(pdf_file)
      end

      describe "the derivatives", skip: LakeshoreTesting.continuous_integration? do
        subject { derivatives }
        before do
          allow(Hydra::Derivatives::FullTextExtract).to receive(:create)
          file.create_derivatives(pdf_file)
        end
        it { is_expected.to contain_exactly(end_with("34-thumbnail.jpeg")) }
      end
    end

    context "with document mime types" do
      let(:document) { File.join(fixture_path, "text.txt") }

      let(:outputs) do
        [
          {
            label:     :access,
            format:    "pdf",
            thumbnail: "file:#{Rails.root}/tmp/test/derivatives/12/34-thumbnail.jpeg",
            access:    "file:#{Rails.root}/tmp/test/derivatives/12/34-access.pdf"
          }
        ]
      end

      let(:extraction) do
        [{ url: kind_of(RDF::URI), container: "extracted_text" }]
      end

      before { allow(file).to receive(:mime_type).and_return("text/plain") }

      it "sends the correct parameters for a text file" do
        expect(Derivatives::DocumentDerivatives).to receive(:create).with(document, outputs: outputs)
        expect(Hydra::Derivatives::FullTextExtract).to receive(:create).with(document, outputs: extraction)
        file.create_derivatives(document)
      end

      describe "the derivatives", skip: LakeshoreTesting.continuous_integration? do
        subject { derivatives }
        before do
          allow(Hydra::Derivatives::FullTextExtract).to receive(:create)
          file.create_derivatives(document)
        end
        it { is_expected.to contain_exactly(end_with("34-access.pdf"), end_with("34-thumbnail.jpeg")) }
      end
    end
  end
end
