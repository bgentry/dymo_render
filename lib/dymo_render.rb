require "dymo_render/page_size"
require "dymo_render/version"
require 'prawn'
require 'nokogiri'
require 'barby'
require 'barby/barcode/code_128'
require 'barby/barcode/qr_code'
require 'barby/outputter/prawn_outputter'

class DymoRender
  FONT_DIRS_MACOS = [
    "#{ENV["HOME"]}/Library/Fonts",
    "/Library/Fonts",
    "/Network/Library/Fonts",
    "/System/Library/Fonts",
  ].freeze

  FONT_DIRS_LINUX = ['/usr/share/fonts/truetype/msttcorefonts'].freeze

  FONT_DIRS = (RUBY_PLATFORM =~ /darwin/ ? FONT_DIRS_MACOS : FONT_DIRS_LINUX).freeze

  # 1440 twips per inch (20 per PDF point)
  TWIP = 1440.0

  # 72 PDF points per inch
  PDF_POINT = 72.0

  attr_reader :doc, :font_dirs, :params, :pdf, :qr_level

  def initialize(xml:, font_dirs: FONT_DIRS, params: {}, qr_level: nil)
    @xml = xml
    @font_dirs = font_dirs
    @params = params
    @qr_level = qr_level
    @doc = Nokogiri::XML(xml)
  end

  def render
    build_pdf
    doc.css('ObjectInfo').each do |object|
      pdf.go_to_page 1
      render_object(object)
    end
    pdf.render
  end

  def has_graphics?
    !doc.css('BarcodeObject').empty?
  end

  def orientation
    @orientation ||= begin
      if doc.css("PaperOrientation").first&.text == "Landscape"
        :landscape
      else
        :portrait
      end
    end
  end

  def landscape?
    orientation == :landscape
  end

  def page_size
    @page_size ||= begin
      elm = doc.css('PaperName').first
      elm && (PageSize.by_name(elm.text) || raise("unknown paper size #{elm.text}"))
    end
  end

  def self.font_file_for_family(font_dirs, family)
    extensions = [".ttf", ".dfont", ".ttc"]
    names = extensions.map { |ext| [family, ext].join }

    font_dirs.each do |dir|
      names.each do |filename|
        file = File.join(dir, filename)
        return file if File.exists?(file)
      end
    end
    nil # not found
  end

  private

  def pdf_margin
    @pdf_margin ||= landscape? ? page_size.pdf_margin_landscape : page_size.pdf_margin
  end

  def pdf_height
    landscape? ? page_size.dimension[0] : page_size.dimension[1]
  end

  def pdf_width
    landscape? ? page_size.dimension[1] : page_size.dimension[0]
  end

  def build_pdf
    @pdf = Prawn::Document.new(
      page_size: page_size.dimension,
      margin: pdf_margin,
      page_layout: orientation,
    )
  end

  def render_object(object_info)
    bounds = object_info.css('Bounds').first.attributes
    x = (bounds['X'].value.to_f * PDF_POINT / TWIP) - pdf_margin[3]
    y = pdf_height - (bounds['Y'].value.to_f * PDF_POINT / TWIP) - pdf_margin[2]
    width = (bounds['Width'].value.to_f * PDF_POINT / TWIP)
    height = (bounds['Height'].value.to_f * PDF_POINT / TWIP)

    object = object_info.children.find(&:element?)
    case object.name
    when 'TextObject'
      render_text_object(object, x, y, width, height)
    when 'ShapeObject'
      render_shape_object(object, x, y, width, height)
    when 'BarcodeObject'
      render_barcode_object(object, x, y, width, height)
    else
      puts "unsupported object type: #{object&.name}"
    end
  end

  def render_text_object(text_object, x, y, width, height)
    foreground = text_object.css('ForeColor').first
    color = color_from_element(foreground)
    draw_rectangle_from_object(text_object, x, y, width, height)
    verticalized = text_object.css('Verticalized').first
    verticalized &&= verticalized.text == 'True'
    name = text_object.css('Name').first
    name &&= name.text
    elements = text_object.css('StyledText Element')
    return if elements.empty?

    font = elements.first.css('Attributes Font').first
    font_family = font ? font.attributes['Family'].value : 'Helvetica'
    size = font.attributes['Size'].value.to_i
    strings = elements.map do |element|
      string = @params[name] || element.css('String').first.text
      string = string.each_char.map { |c| [c, "\n"] }.flatten.join if verticalized
      string
    end
    valign = valign_from_text_object(text_object)
    begin
      pdf.fill_color color
      font_file = self.class.font_file_for_family(font_dirs, font_family)
      pdf.font(font_file || raise("missing font #{font_family}"))
      # horizontal padding of 1 point
      x += 1
      width -= 2
      (box, actual_size) = text_box_with_font_size(
        strings.join,
        size: size,
        character_spacing: 0,
        at: [x, y],
        width: width,
        height: height,
        overflow: overflow_from_text_object(text_object),
        align: align_from_text_object(text_object),
        valign: valign,
        disable_wrap_by_char: true,
        single_line: !verticalized
      )
      # on bottom-aligned boxes, Dymo counts the height of character descenders
      box.at[1] += box.descender if valign == :bottom
      box.render
    rescue Prawn::Errors::CannotFit
      puts 'cannot fit'
    end
  end

  def text_box_with_font_size(text, options = {})
    box = Prawn::Text::Box.new(text, options.merge(document: pdf))
    box.render(dry_run: true)
    size = box.instance_eval { @font_size }
    [box, size]
  end

  def draw_rectangle_from_object(text_object, x, y, width, height)
    background = text_object.css('BackColor').first
    return unless background
    alpha = background.attributes['Alpha'].value.to_i
    return if alpha.zero?
    pdf.fill_color color_from_element(background)
    pdf.rectangle [x, y], width, height
    pdf.fill
  end

  def color_from_element(element)
    red   = element.attributes['Red'].value.to_i
    green = element.attributes['Green'].value.to_i
    blue  = element.attributes['Blue'].value.to_i
    Prawn::Graphics::Color.rgb2hex([red, green, blue])
  end

  VALIGNS = {
    'Top'    => :top,
    'Bottom' => :bottom,
    'Middle' => :center
  }.freeze

  def valign_from_text_object(text_object)
    VALIGNS[text_object.css('VerticalAlignment').first.text] || :top
  end

  ALIGNS = {
    'Left'   => :left,
    'Right'  => :right,
    'Center' => :center
  }.freeze

  def align_from_text_object(text_object)
    ALIGNS[text_object.css('HorizontalAlignment').first.text] || :left
  end

  OVERFLOWS = {
    'None'        => :truncate,
    'ShrinkToFit' => :shrink_to_fit
  }.freeze

  def overflow_from_text_object(text_object)
    OVERFLOWS[text_object.css('TextFitMode').first.text] || :truncate
  end

  HORIZONTAL_LINE_VERTICAL_FUDGE_BY = -2.5

  def render_shape_object(shape_object, x, y, width, height)
    case shape_type = shape_object.css('ShapeType').first.text
    when 'HorizontalLine'
      pdf.line_width height
      pdf.horizontal_line x, x + width, at: y + HORIZONTAL_LINE_VERTICAL_FUDGE_BY
      pdf.stroke
    when 'Rectangle'
      top_left = [x, y]
      line_width = shape_object.css("LineWidth").first.text.to_f / TWIP * PDF_POINT

      pdf.line_width line_width
      pdf.rectangle top_left, width, height
      pdf.stroke
    else
      puts "unknown shape type #{shape_type}"
    end
  end

  # (72 pts/in) / (300 dots/in)
  POINTS_PER_DOT = 0.24

  # fixed number of dots per QR dot in each dimension:
  DIM_PT_SIZES = {
    "Small" => POINTS_PER_DOT * 4,
    "Medium" => POINTS_PER_DOT * 5,
    "Large" => POINTS_PER_DOT * 6,
  }.freeze

  def render_barcode_object(barcode_object, x, y, width, height)
    case barcode_type = barcode_object.css('Type').first.text
    when 'QRCode'
      content = barcode_object.css('Text').first.text
      code = Barby::QrCode.new(content, level: qr_level)
      outputter = Barby::PrawnOutputter.new(code)
      num_dots = outputter.full_width # number of dots in QR

      size = barcode_object.css('Size').first&.text || "Small"
      dim = DIM_PT_SIZES[size]

      # If the resulting size in either dimension is smaller than that
      # dimension's specified size, adjust so the code is centered in the
      # bounding box.
      xadjust = (width - dim * num_dots).to_f / 2
      yadjust = (height - dim * num_dots).to_f / 2

      xpos = x + xadjust
      ypos = y - height + yadjust

      outputter.annotate_pdf(pdf, { x: xpos, y: ypos, xdim: dim, ydim: dim, unbleed: 0.05 });
    when 'Code128Auto'
      render_barcode_code128(barcode_object, x, y, width, height, nil)
    when 'Code128A', 'Code128B', 'Code128C'
      type = barcode_type.sub('Code128', '')
      render_barcode_code128(barcode_object, x, y, width, height, type)
    else
      puts "unknown barcode type: #{barcode_type}"
    end
  end

  def render_barcode_code128(barcode_object, x, y, width, height, type)
    content = barcode_object.css('Text').first.text
    code = Barby::Code128.new(content, type)
    outputter = Barby::PrawnOutputter.new(code)

    barcode_height = height
    barcode_y = y

    text_position = barcode_object.css("TextPosition").first&.text
    if %w{Top Bottom}.include?(text_position)
      font_element = barcode_object.css("TextFont").first
      font_family = font_element.attribute("Family").value
      font_size = font_element.attribute("Size").value.to_f
      color = color_from_element(barcode_object.css("ForeColor").first)
      valign = VALIGNS[text_position]

      pdf.fill_color color
      font_file = self.class.font_file_for_family(font_dirs, font_family)
      pdf.font(font_file || raise("missing font #{font_family}"))
      # horizontal padding of 1 point
      x += 1
      width -= 2
      (box, actual_size) = text_box_with_font_size(
        content,
        size: font_size,
        character_spacing: 0,
        at: [x, y],
        width: width,
        height: height,
        overflow: :truncate,
        align: :center,
        valign: valign,
        disable_wrap_by_char: true,
        single_line: true,
      )
      # on bottom-aligned boxes, Dymo counts the height of character descenders
      box.at[1] += box.descender if valign == :bottom
      box.render
      code_offset = box.height * 1.25
      barcode_height -= code_offset
      barcode_y -= code_offset if valign == :top
    end

    num_dots_x = outputter.full_width
    xdim = width.to_f / num_dots_x
    center_x = x + width.to_f / 2

    # ensure mandatory 10 module widths of space on left and right of barcode:
    # https://en.wikipedia.org/wiki/Code_128#Quiet_zone
    max_code_width = width - 20 * xdim
    if (num_dots_x * xdim) > max_code_width
      width = max_code_width
      xdim = max_code_width / num_dots_x
    end

    # center in the x direction
    xpos = center_x - width.to_f / 2
    ypos = barcode_y - barcode_height

    outputter.annotate_pdf(pdf, { x: xpos, y: ypos, xdim: xdim, height: barcode_height });
  end
end
