require "spec_helper"

describe Faye::Hazelcast do
  let(:engine_opts) do
    {
      type: Faye::Hazelcast,
      hazelcast: {
        'hazelcast.logging.type' => 'none'
      }
    }
  end

  before do
    # engine.hazelcast.should eq ''
    # @clients[:anything] = 'nonexistentclient'
  end

  after do
    # engine.disconnect
    # engine.connected.each { |c| engine.destroy_client(c) }
  end

  # it_should_behave_like "faye engine"
  it_should_behave_like "distributed engine"

  # describe '#client_exists' do
  #   let(:engine) { create_engine }
  #
  #   it "returns false if the (non-nil) client id does not exist" do
  #     engine.client_exists('does-not-exist') do |actual|
  #       actual.should == false
  #       resume.call
  #     end
  #   end
  # end
end
