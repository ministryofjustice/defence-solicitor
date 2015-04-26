module DefenceRequestHelpers
  def stub_defence_request_with(method:, value:)
    allow_any_instance_of(DefenceRequest).
      to receive(method).and_return(value)
  end

  def expect_email_with_case_details_to_have_been_sent_to_assigned_solicitor
    expect(ActionMailer::Base.deliveries.size).to eq 1
  end

  def abort_defence_request(options = {})
    click_link "Abort"
    fill_in "Reason aborted", with: options.fetch(:reason) { "Reason for abort" }
    click_button "Abort"
  end

  def fill_in_defence_request_form(options = {})
    within ".solicitor-details" do
      fill_in "Full Name", with: "Bob Smith"
      fill_in "Name of firm", with: "Acme Solicitors"
      fill_in "Telephone number", with: "0207 284 0000"
    end

    if options.fetch(:edit) { false }
      within ".case-details" do
        fill_in "Custody number", with: "#CUST-9876"
        fill_in "Offences", with: "BadMurder"
        fill_in "defence_request_interview_start_time_day", with: "01"
        fill_in "defence_request_interview_start_time_month", with: "01"
        fill_in "defence_request_interview_start_time_year", with: "2001"
        fill_in "defence_request_interview_start_time_hour", with: "01"
        fill_in "defence_request_interview_start_time_min", with: "01"
      end
    else
      within ".case-details" do
        fill_in "Custody number", with: "#CUST-01234"
        fill_in "defence_request_custody_address", with: "The Nick"
        fill_in "defence_request_investigating_officer_name", with: "Dave Mc.Copper"
        fill_in "defence_request_investigating_officer_shoulder_number", with: "987654"
        fill_in "defence_request_investigating_officer_contact_number", with: "0207 111 0000"
        fill_in "Offences", with: "BadMurder"
        fill_in "defence_request_circumstances_of_arrest", with: "He looked a bit shady"
        choose "defence_request_fit_for_interview_true"
        fill_in "defence_request_time_of_arrest_day", with: "02"
        fill_in "defence_request_time_of_arrest_month", with: "02"
        fill_in "defence_request_time_of_arrest_year", with: "2002"
        fill_in "defence_request_time_of_arrest_hour", with: "02"
        fill_in "defence_request_time_of_arrest_min", with: "02"
        fill_in "defence_request_time_of_arrival_day", with: "01"
        fill_in "defence_request_time_of_arrival_month", with: "01"
        fill_in "defence_request_time_of_arrival_year", with: "2001"
        fill_in "defence_request_time_of_arrival_hour", with: "01"
        fill_in "defence_request_time_of_arrival_min", with: "01"
        fill_in "defence_request_time_of_detention_authorised_day", with: "03"
        fill_in "defence_request_time_of_detention_authorised_month", with: "03"
        fill_in "defence_request_time_of_detention_authorised_year", with: "2003"
        fill_in "defence_request_time_of_detention_authorised_hour", with: "03"
        fill_in "defence_request_time_of_detention_authorised_min", with: "03"
      end
    end

    within ".detainee" do
      fill_in "Full Name", with: "Mannie Badder"
      choose "Male"
      fill_in "Age", with: "39"
      fill_in "defence_request_date_of_birth_year", with: "1976"
      fill_in "defence_request_date_of_birth_month", with: "01"
      fill_in "defence_request_date_of_birth_day", with: "01"
      fill_in "defence_request_house_name", with: "House of the rising sun"
      fill_in "defence_request_address_1", with: "Letsby Avenue"
      fill_in "defence_request_address_2", with: "Right up my street"
      fill_in "defence_request_city", with: "London"
      fill_in "defence_request_county", with: "Greater London"
      fill_in "defence_request_postcode", with: "XX1 1XX"
      choose "defence_request_appropriate_adult_false"
      choose "defence_request_interpreter_required_false"
    end
    fill_in "Comments", with: "This is a very bad man. Send him down..."
  end

  def an_audit_should_exist_for_the_defence_request_creation
    expect(DefenceRequest.first.audits.length).to eq 1
    audit = DefenceRequest.first.audits.first

    expect(audit.auditable_type).to eq "DefenceRequest"
    expect(audit.action).to eq "create"
  end

  def stub_solicitor_search_for_dave_oreilly
    body = File.open "spec/fixtures/dave_oreilly_solicitor_search.json"
    stub_request(:post, "http://solicitor-search.herokuapp.com/search/?q=Dave%20O'Reilly").
      to_return(body: body, status: 200)
  end

  def stub_solicitor_search_for_bob_smith
    body = File.open "spec/fixtures/bob_smith_solicitor_search.json"
    stub_request(:post, "http://solicitor-search.herokuapp.com/search/?q=Bob%20Smith").
      to_return(body: body, status: 200)
  end

  def stub_solicitor_search_for_barry_jones
    body = File.open "spec/fixtures/barry_jones_solicitor_search.json"
    stub_request(:post, "http://solicitor-search.herokuapp.com/search/?q=Barry%20Jones").
      to_return(body: body, status: 200)
  end

  def stub_solicitor_search_for_mystery_man
    body = {solicitors: [], firms: []}.to_json
    stub_request(:post, "http://solicitor-search.herokuapp.com/search/?q=Mystery%20Man").
      to_return(body: body, status: 200)
  end
end