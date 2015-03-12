require "rails_helper"

RSpec.feature "Custody Center Operatives viewing their dashboard" do
    include ActiveJobHelper
    include DashboardHelper

    let!(:dr_draft) { create(:defence_request, :draft) }
    let!(:dr_open) { create(:defence_request, :opened) }
    let!(:dr_accepted) { create(:defence_request, :accepted) }
    let(:cco_user2){ create :cco_user }

    before :each do
      create_role_and_login("cco")
    end

    specify "can see tables of \"draft\" and \"open\" defence requests" do
      visit defence_requests_path

      within ".draft-defence-request" do
        expect(page).to have_content(dr_draft.solicitor_name)
      end

      within ".open-defence-request" do
        expect(page).to have_content(dr_open.solicitor_name)
      end
    end

    specify "can see the dashboard with refreshed data after a period", js: true, short_dashboard_refresh: true do
      visit defence_requests_path

      within "#defence_request_#{dr_draft.id}" do
        expect(page).to have_content(dr_draft.solicitor_name)
      end

      within "#defence_request_#{dr_open.id}" do
        expect(page).to have_content(dr_open.solicitor_name)
      end

      dr_draft.update(solicitor_name: "New Solicitor")
      dr_open.update(solicitor_name: "New Solicitor2")

      wait_for_dashboard_refresh

      within "#defence_request_#{dr_draft.id}" do
        expect(page).to have_content("New Solicitor")
      end
      within "#defence_request_#{dr_open.id}" do
        expect(page).to have_content("New Solicitor2")
      end

    end

    specify "can resend case details of an defence request to the assigned solicitor", js: true do
      visit defence_requests_path

      within ".accepted-defence-request" do
        click_button "Resend details"
      end

      page.execute_script "window.confirm"

      expect(page).to have_content("Details successfully sent")
      an_email_has_been_sent
    end

    specify "are shown an error message if case details cannot be resent", js: true do
      visit defence_requests_path

      dr_details_can_not_be_resent_for_some_reason dr_accepted
      within ".accepted-defence-request" do
        click_button "Resend details"
      end

      page.execute_script "window.confirm"

      expect(page).to have_content("Details were not sent")
    end
end

def dr_details_can_not_be_resent_for_some_reason defence_request
  expect(DefenceRequest).to receive(:find).with(defence_request.id.to_s) { defence_request }
  expect(defence_request).to receive(:resend_details) { false }
end
