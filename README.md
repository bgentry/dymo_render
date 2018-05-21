# Dymo Render

Render a PDF from the DYMO Label software's XML `.label` format. This is the same format used by their JavaScript SDK and by their desktop apps.

## Installation

```rb
gem "dymo_render"
```

## Usage

```rb
xml_content = File.read("sample.label")
pdf = DymoRender.new(xml: xml_content).render
File.write("out.pdf", pdf)
```

## License

This project uses the BSD 2-clause simplified license from the dymo-printer-agent project.

## Thanks

This project uses code extracted from Tim Morgan's [dymo-printer-agent](https://github.com/seven1m/dymo-printer-agent).
