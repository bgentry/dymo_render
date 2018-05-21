require "dymo-render"
require "pry"

module DymoRenderSpecHelper
  extend RSpec::Matchers::DSL

  FILE_FIXTURE_PATH = File.expand_path("fixtures/files", __dir__)

  def file_fixture(fixture_name)
    path = Pathname.new(File.join(FILE_FIXTURE_PATH, fixture_name))
  
    if path.exist?
      path
    else
      msg = "the directory '%s' does not contain a file named '%s'"
      raise ArgumentError, msg % [FILE_FIXTURE_PATH, fixture_name]
    end
  end

  matcher :be_truthy do
    match do |actual|
      actual
    end
  end
end

RSpec.configure do |config|
  config.include DymoRenderSpecHelper
end
