RSpec::Matchers.define :be_an_unsuccessful_response do
  match do |actual|
    actual.successful? == false &&
    actual.code == 1 &&
    actual.output == 'it blew up' &&
    actual.data == nil
  end
end
