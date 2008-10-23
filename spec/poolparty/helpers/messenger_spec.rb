require File.dirname(__FILE__) + '/../spec_helper'

setup_cl

include PoolParty::Messenger

describe "Messenger" do
  it "should have the method messenger_send!" do
    Messenger.respond_to?(:messenger_send!).should == true
  end
  it "should call send_cmd on the client" do
    Messenger.messenger_send!('send_cmd ["echo hi"]', true).should =~ /-run pm_client send_cmd/
  end
end