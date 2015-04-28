require "rails_helper"

RSpec.feature "Solicitors viewing aborted requests" do
  specify "can see 'aborted' defence requests" do
    solicitor = create :solicitor_user
    aborted_defence_request =
      create(
        :defence_request,
        :aborted,
        solicitor_uid: solicitor.uid,
        organisation_uid: solicitor.organisation_uids.first
    )

    login_with solicitor

    click_link "Closed"
    click_link "Show"

    expect(page).
      to have_content "This case has been aborted for the following reason"
    expect(page).to have_content aborted_defence_request.reason_aborted
  end
end
