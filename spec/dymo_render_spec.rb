require "spec_helper"

describe DymoRender do
  let(:sample_label_qr) { File.read(file_fixture("sample_qr.label")) }

  describe ".new" do
    it "does not error" do
      expect { DymoRender.new(xml: sample_label_qr) }.not_to raise_error
    end
  end

  describe "#render" do
    subject { DymoRender.new(xml: label_xml).render }

    context "with a sample QR label" do
      let(:label_xml) { sample_label_qr }

      it "does not error" do
        expect { subject }.not_to raise_error
      end
    end
  end
end
