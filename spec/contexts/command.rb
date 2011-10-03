shared_context 'command_setup' do
  before do
    @string_io = StringIO.new
    Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))

    @all_running_response_mock = mock('all_running_response')
    @exists_response_mock = mock('exists_response')
    @fusion_running_response_mock = mock('fusion_running_response_mock')
    @vm_mock = mock('vm_mock')
  end

end
