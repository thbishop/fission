RSpec::Matchers.define :be_an_unsuccessful_response do |output|
  output ||= 'it blew up'

  match do |actual|
    actual.successful? == false &&
    actual.code == 1 &&
    actual.output == output &&
    actual.data == nil
  end
end
