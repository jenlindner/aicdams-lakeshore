require 'rails_helper'

describe HomepageController do
  routes { Sufia::Engine.routes }
  describe "#index" do
    context "with a public user" do
      before { get :index }
      subject { response }
      it { is_expected.to be_unauthorized }
    end

    context "with a logged in user" do
      include_context "authenticated saml user"
      it "sets the number of facet counts for resource type" do
        get :index
        assigns(:resource_types).should_not be_nil
      end
    end
  end
end
