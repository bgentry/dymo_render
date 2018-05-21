require "spec_helper"

describe DymoRender do
  let(:font_dirs) { [File.join(__dir__, "fixtures", "files")] }
  let(:sample_label_qr) { File.read(file_fixture("sample_qr.label")) }
  let(:sample_label_qr_code128) { File.read(file_fixture("sample_qr_code128.label")) }

  let(:sample_label_qr_rendered) { file_fixture("sample_qr.pdf") }
  let(:sample_label_qr_code128_rendered) { file_fixture("sample_qr_code128.pdf") }

  describe ".new" do
    it "does not error" do
      expect { DymoRender.new(xml: sample_label_qr) }.not_to raise_error
    end
  end

  describe "#render" do
    subject { DymoRender.new(xml: label_xml, font_dirs: font_dirs) }

    context "with a sample QR label" do
      let(:label_xml) { sample_label_qr }

      it "does not error" do
        expect { subject.render }.not_to raise_error
      end

      it "updates the rendered PDF on disk" do
        pdf_result = subject.render
        File.write(sample_label_qr_rendered, pdf_result)
      end
    end

    context "with a sample QR + Code 128 Auto label" do
      let(:label_xml) { sample_label_qr_code128 }

      it "does not error" do
        expect { subject.render }.not_to raise_error
      end

      it "updates the rendered PDF on disk" do
        pdf_result = subject.render
        File.write(sample_label_qr_code128_rendered, pdf_result)
      end
    end
  end
end
