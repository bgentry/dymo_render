class DymoRender
  class PageSize
    # imageable_area is [Left, Top, Right, Bottom]
    ALL_SIZES = [
      {
        id: "Address",
        name: "30252 Address",
        dimension: [78.96, 252.0],
        imageable_area: [4.32, 4.32, 76.07, 235.44],
        landscape: true,
        slug: "w79h252",
      },
      {
        id: "ReturnAddress",
        name: "30330 Return Address",
        dimension: [54.0, 144.0],
        imageable_area: [4.08, 4.32, 51.12, 127.68],
        landscape: true,
        slug: "w54h144.1",
      },
      {
        id: "Small30334",
        name: "30334 2-1/4 in x 1-1/4 in",
        dimension: [162.0, 90.0],
        imageable_area: [2.88, 4.32, 159.12, 85.68],
        landscape: false,
        slug: "30334_2-1_4_in_x_1-1_4_in",
      },
    ].freeze

    attr_reader :id, :name, :dimension, :imageable_area, :landscape, :slug

    def initialize(id: "", name:, dimension:, imageable_area:, landscape:, slug:)
      @id = id
      @name = name
      @dimension = dimension
      @imageable_area = imageable_area
      @landscape = landscape
      @slug = slug
    end

    def landscape?
      landscape
    end

    def layout
      landscape? ? :landscape : :portrait
    end

    def pdf_height
      landscape? ? dimension[0] : dimension[1]
    end

    def pdf_width
      landscape? ? dimension[1] : dimension[0]
    end

    # pdf_margin returns the page margins as required by Prawn: [top, right, bottom, left]
    def pdf_margin
      if landscape?
        [ margin_left, margin_top, margin_right, margin_bottom ]
      else
        [ margin_top, margin_right, margin_bottom, margin_left ]
      end
    end

    def margin_left
      imageable_area[0]
    end

    def margin_top
      imageable_area[1]
    end

    def margin_right
      dimension[0] - imageable_area[2]
    end

    def margin_bottom
      dimension[1] - imageable_area[3]
    end

    def self.by_name(name)
      data = ALL_SIZES.find { |s| s[:name] == name }
      new(data) if data
    end
  end
end
