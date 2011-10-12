shared_context 'command_setup' do
  before do
    @string_io = StringIO.new
    ui_stub = Fission::UI.new(@string_io)
    Fission::UI.stub!(:new).and_return(ui_stub)

    @all_running_response_mock = mock('all_running_response')
    @state_response_mock = mock('state_response')
    @exists_response_mock = mock('exists_response')
    @fusion_running_response_mock = mock('fusion_running_response_mock')
    @vm_mock = mock('vm_mock')
  end

end
