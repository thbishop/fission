require 'spec_helper'

describe Fission do
  describe "config" do
    it "should load a config object" do
      Fission.config.should be_a Fission::Config
    end
  end

  describe "ui" do
    it "should load a ui object" do
      Fission.ui.should be_a Fission::UI
    end
  end
end
