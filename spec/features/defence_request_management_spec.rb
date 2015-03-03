require 'rails_helper'
require 'json'

RSpec.feature 'defence request creation' do

  context 'Create' do
    context 'as cso' do
      before :each do
        create_role_and_login('cso')
      end

      scenario 'Does not see the DSCC field on the Defence Request form' do
        visit root_path
        click_link 'New Defence Request'

        expect(page).not_to have_field('DSCC Number')
      end

      scenario 'Does not see the solicitor_time_of_arrival field on the Defence Request form' do
        visit root_path
        click_link 'New Defence Request'

        expect(page).not_to have_field('Expected Solicitor Time of Arrival')
      end

      scenario 'Filling in form manually for own solicitor', js: true do
        visit root_path
        click_link 'New Defence Request'
        expect(page).to have_content ('New Defence Request')

        within '.new_defence_request' do
          choose 'Own'
          within '.solicitor-details' do
            fill_in 'Full Name', with: 'Bob Smith'
            fill_in 'Name of firm', with: 'Acme Solicitors'
            fill_in 'Telephone number', with: '0207 284 0000'
          end

          within '.case-details' do
            fill_in 'Custody number', with: '#CUST-01234'
            fill_in 'Allegations', with: 'BadMurder'
            fill_in 'defence_request_time_of_arrival_day', with: '01'
            fill_in 'defence_request_time_of_arrival_month', with: '01'
            fill_in 'defence_request_time_of_arrival_year', with: '2001'
            fill_in 'defence_request_time_of_arrival_hour', with: '01'
            fill_in 'defence_request_time_of_arrival_min', with: '01'
          end

          within '.detainee' do
            fill_in 'Full Name', with: 'Mannie Badder'
            choose 'Male'
            fill_in 'Age', with: '39'
            fill_in 'defence_request_date_of_birth_year', with: '1976'
            fill_in 'defence_request_date_of_birth_month', with: '01'
            fill_in 'defence_request_date_of_birth_day', with: '01'
            choose 'No'
          end
          fill_in 'Comments', with: 'This is a very bad man. Send him down...'
          click_button 'Create Defence Request'
        end
        an_audit_should_exist_for_the_defence_request_creation
        expect(page).to have_content 'Bob Smith'
        expect(page).to have_content 'Defence Request successfully created'
      end

      scenario 'selecting own solicitor and choosing from search box', js: true do
        stub_solicitor_search_for_bob_smith
        visit root_path
        click_link 'New Defence Request'
        choose 'Own'
        fill_in 'q', with: "Bob Smith"

        find('.solicitor-search', match: :first).click
        expect(page).to have_content 'Bobson Smith'
        expect(page).to have_content 'Bobby Bob Smithson'

        click_link 'Bobson Smith'
        expect(page).to_not have_content 'Bobby Bob Smithson'
        within '.solicitor-details' do
          expect(page).to have_field 'Full Name', with: 'Bobson Smith'
          expect(page).to have_field 'Name of firm', with: 'Kreiger LLC'
          expect(page).to have_field 'Telephone number', with: '248.412.8095'
        end
      end

      scenario 'performing multiple own solicitor searches', js: true do
        stub_solicitor_search_for_bob_smith
        stub_solicitor_search_for_barry_jones

        visit root_path
        click_link 'New Defence Request'
        choose 'Own'
        fill_in 'q', with: "Bob Smith"
        find('.solicitor-search', match: :first).click

        expect(page).to have_content 'Bobson Smith'

        fill_in 'q', with: "Barry Jones"
        click_button 'Search'

        find_link('Barry Jones').visible?
        expect(page).to_not have_content 'Bobson Smith'
      end

      scenario "searching for someone who doesn't exist", js: true do
        stub_solicitor_search_for_mystery_man

        visit root_path
        click_link 'New Defence Request'
        choose 'Own'
        fill_in 'q', with: "Mystery Man"
        find('.solicitor-search', match: :first).click

        expect(page).to have_content 'No results found'
      end

      scenario "using Close link to clear solicitor search results", js: true do
        stub_solicitor_search_for_bob_smith
        visit root_path
        click_link 'New Defence Request'
        choose 'Own'
        fill_in 'q', with: "Bob Smith"
        find('.solicitor-search', match: :first).click
        expect(page).to have_content 'Bobson Smith'

        within('.solicitor-results-list') do
        click_link("Close")
        end
        expect(page).not_to have_content 'Bobson Smith'
      end

      scenario "pressing ESC clears solicitor search results", js: true do
        stub_solicitor_search_for_bob_smith
        visit root_path
        click_link 'New Defence Request'
        choose 'Own'
        fill_in 'q', with: "Bob Smith"

        find('.solicitor-search', match: :first).click
        expect(page).to have_content 'Bobson Smith'

        page.execute_script("$('body').trigger($.Event(\"keydown\", { keyCode: 27 }))")
        expect(page).not_to have_content 'Bobson Smith'
      end

      scenario "toggling duty or own", js: true do
        stub_solicitor_search_for_bob_smith

        visit root_path
        click_link 'New Defence Request'
        choose 'Own'
        fill_in 'q', with: "Bob Smith"
        find('.solicitor-search', match: :first).click
        click_link 'Bobson Smith'
        choose 'Duty'

        expect(page).to_not have_content 'Bobson Smith'

        choose 'Own'
        expect(page).to have_field 'q', with: ''
      end
    end

  end

  context 'close' do
    context 'as cso' do
      before :each do
        create_role_and_login('cso')
      end

      let!(:dr_created) { create(:defence_request) }

      scenario 'closing a DR from the dashboard' do
        visit root_path
        within "#defence_request_#{dr_created.id}" do
          click_link 'Close'
        end
        expect(page).to have_content('Close the Defence Request')
        click_button 'Close'
        expect(page).to have_content("Feedback: can't be blank")
        expect(page).to have_content('Close the Defence Request')

        fill_in 'Feedback', with: 'I just cant take it any more...'
        click_button 'Close'
        expect(page).to have_content('Defence Request successfully closed')
        expect(page).to have_content('Custody Suite Officer Dashboard')
        dr_created.reload
        expect(dr_created.state).to eq 'closed'
      end
      scenario 'closing a DR from the edit' do
        visit root_path
        within "#defence_request_#{dr_created.id}" do
          click_link 'Edit'
        end
        click_link 'Close'
        expect(page).to have_content('Close the Defence Request')
        click_button 'Close'
        expect(page).to have_content("Feedback: can't be blank")
        expect(page).to have_content('Close the Defence Request')

        fill_in 'Feedback', with: 'I just cant take it any more...'
        click_button 'Close'
        expect(page).to have_content('Defence Request successfully closed')
        expect(page).to have_content('Custody Suite Officer Dashboard')
        dr_created.reload
        expect(dr_created.state).to eq 'closed'
      end
    end
    context 'as cco' do
      before :each do
        create_role_and_login('cco')
      end

      let!(:dr_created) { create(:defence_request) }

      scenario 'closing a DR from the dashboard' do
        visit root_path
        within "#defence_request_#{dr_created.id}" do
          click_link 'Close'
        end
        expect(page).to have_content('Close the Defence Request')
        click_button 'Close'
        expect(page).to have_content("Feedback: can't be blank")
        expect(page).to have_content('Close the Defence Request')

        fill_in 'Feedback', with: 'I just cant take it any more...'
        click_button 'Close'
        expect(page).to have_content('Defence Request successfully closed')
        expect(page).to have_content('Call Center Operative Dashboard')
        dr_created.reload
        expect(dr_created.state).to eq 'closed'
      end
    end
  end

  context 'Edit' do
    context 'as cso' do

      before :each do
        create_role_and_login('cso')
      end

      let!(:dr_1) { create(:defence_request) }

      scenario 'editing a DR' do
        visit root_path
        within "#defence_request_#{dr_1.id}" do
          click_link 'Edit'
        end
        expect(page).to have_content ('Edit Defence Request')

        within '.edit_defence_request' do
          within '.solicitor-details' do
            fill_in 'Full Name', with: 'Dave Smith'
            fill_in 'Name of firm', with: 'Broken Solicitors'
            fill_in 'Telephone number', with: '0207 284 9999'
            expect(page).to_not have_selector('defence_request_solicitor_time_of_arrival_1i')
          end

          within '.case-details' do
            fill_in 'Custody number', with: '#CUST-9876'
            fill_in 'Allegations', with: 'BadMurder'
            fill_in 'defence_request_interview_start_time_day', with: '01'
            fill_in 'defence_request_interview_start_time_month', with: '01'
            fill_in 'defence_request_interview_start_time_year', with: '2001'
            fill_in 'defence_request_interview_start_time_hour', with: '01'
            fill_in 'defence_request_interview_start_time_min', with: '01'

          end

          within '.detainee' do
            fill_in 'Full Name', with: 'Mannie Badder'
            choose 'Male'
            fill_in 'Age', with: '39'
            fill_in 'defence_request_date_of_birth_year', with: '1976'
            fill_in 'defence_request_date_of_birth_month', with: '01'
            fill_in 'defence_request_date_of_birth_day', with: '01'
            choose 'No'
          end

          within '.detainee' do
            fill_in 'Full Name', with: 'Annie Nother'
            choose 'Female'
            fill_in 'Age', with: '28'
            fill_in 'defence_request_date_of_birth_year', with: '1986'
            fill_in 'defence_request_date_of_birth_month', with: '12'
            fill_in 'defence_request_date_of_birth_day', with: '12'
            choose 'Yes'
          end
          fill_in 'Comments', with: 'I fought the law...'
          click_button 'Update Defence Request'
        end

        within "#defence_request_#{dr_1.id}" do
          expect(page).to have_content('Dave Smith')
          expect(page).to have_content('02072849999')
          expect(page).to have_content('#CUST-9876')
          expect(page).to have_content('BadMurder')
          expect(page).to have_content('Annie')
          expect(page).to have_content('Nother')
        end
      end
    end

    context 'as cco' do
      before :each do
        create_role_and_login('cco')
      end

      context 'for "own" solicitor' do
        let!(:dr) { create(:own_solicitor) }
        let!(:opened_dr) { create(:defence_request, :opened, :with_solicitor, cco: User.first) }
        scenario 'must open a Defence Request before editing' do
          visit root_path
          within "#defence_request_#{dr.id}" do
            expect(page).not_to have_link('Edit')
            click_button 'Open'
          end

          within "#defence_request_#{dr.id}" do
            expect(page).to have_link('Edit')
            click_link 'Edit'
          end
          expect(current_path).to eq(edit_defence_request_path(dr))
        end

        scenario 'manually changing a solicitors details' do
          visit root_path
          within "#defence_request_#{opened_dr.id}" do
            click_link 'Edit'
          end

          within '.solicitor-details' do
            fill_in 'Full Name', with: 'Henry Billy Bob'
            fill_in 'Name of firm', with: 'Cheap Skate Law'
            fill_in 'Telephone number', with: '00112233445566'
          end

          click_button 'Update Defence Request'
          expect(current_path).to eq(defence_requests_path)

          within "#defence_request_#{opened_dr.id}" do
            expect(page).to have_content 'Henry Billy Bob'
            expect(page).to have_content '00112233445566'
          end
        end

        scenario 'editing a DR DSCC number (multiple times)' do
          visit root_path
          within "#defence_request_#{opened_dr.id}" do
            click_link 'Edit'
          end
          fill_in 'DSCC number', with: 'NUMBERWANG'
          click_button 'Update Defence Request'
          expect(page).to have_content 'Defence Request successfully updated'
          within "#defence_request_#{opened_dr.id}" do
            click_link 'Edit'
          end
          expect(page).to have_field 'DSCC number', with: 'NUMBERWANG'
          fill_in 'DSCC number', with: 'T-1000'
          click_button 'Update Defence Request'
          expect(page).to have_content 'Defence Request successfully updated'
        end

        scenario 'I cant see an accepted button for created DR`s' do
          visit root_path
          within ".created-defence-request" do
            expect(page).to_not have_button 'Accepted'
          end
        end

        scenario 'I CANT see an accepted button for open DR`s without a DSCC number' do
          visit root_path
          within ".open-defence-request" do
            expect(page).to_not have_button 'Accepted'
          end
        end

        scenario 'I see an accepted button for open DR`s with a DSCC number' do
          opened_dr.update(dscc_number: '012345')
          visit root_path
          within "#defence_request_#{opened_dr.id}" do
            click_button 'Accepted'
          end
          within ".accepted-defence-request" do
            expect(page).to have_content(opened_dr.solicitor_name)
          end
        end

        scenario 'can choose "Update and Accept" from the edit page after adding a dscc number' do
          visit root_path

          within "#defence_request_#{opened_dr.id}" do
            click_link 'Edit'
          end
          fill_in 'DSCC number', with: '123456'

          click_button 'Update and Accept'
          within ".accepted-defence-request" do
            expect(page).to have_content(opened_dr.solicitor_name)
          end
        end

        scenario 'can NOT choose "Update and Accept" from the edit page without adding a dscc number' do
          visit root_path

          within "#defence_request_#{opened_dr.id}" do
            click_link 'Edit'
          end

          click_button 'Update and Accept'
          expect(page).to have_content('A Valid DSCC number is required to update and accept a Defence Request')
        end

        scenario 'editing a DR expected_solicitor_time for accepted DR' do
          visit root_path

          within "#defence_request_#{opened_dr.id}" do
            click_link 'Edit'
          end

          within '.solicitor-details' do
            expect(page).to_not have_selector('defence_request_solicitor_time_of_arrival_1i')
          end

          fill_in 'DSCC number', with: '123456'

          click_button 'Update and Accept'

          within ".accepted-defence-request" do
            expect(page).to have_content(opened_dr.solicitor_name)
          end

          within ".accepted-defence-request" do
            click_link 'Edit'
          end

          within '.solicitor-details' do
            fill_in 'defence_request_solicitor_time_of_arrival_day', with: '01'
            fill_in 'defence_request_solicitor_time_of_arrival_month', with: '01'
            fill_in 'defence_request_solicitor_time_of_arrival_year', with: '2001'
            fill_in 'defence_request_solicitor_time_of_arrival_hour', with: '01'
            fill_in 'defence_request_solicitor_time_of_arrival_min', with: '01'
          end
          click_button 'Update Defence Request'
          expect(page).to have_content 'Defence Request successfully updated'
          within ".accepted-defence-request" do
            click_link 'Show'
          end
          expect(page).to have_content('1 January 2001 - 01:01')

        end
      end

      context 'for "duty" solicitor' do
        let!(:duty_solicitor_dr) { create(:defence_request, :duty_solicitor, :opened, cco: User.first) }
        scenario 'can NOT mark a dr as "solicitor accepted" without solicitor details from the DASHBOARD' do
          visit root_path
          within ".open-defence-request" do
            expect(page).to_not have_button 'Accepted'
          end
        end
        scenario 'can NOT mark a dr as "solicitor accepted" without solicitor details from the EDIT' do
          visit root_path

          within "#defence_request_#{duty_solicitor_dr.id}" do
            click_link 'Edit'
          end
          click_button 'Update and Accept'
          expect(page).to have_content('Valid solicitor details are required to update and accept a Defence Request')

          within '.solicitor-details' do
            fill_in 'Full Name', with: 'Dodgy Dave'
          end
          click_button 'Update and Accept'
          expect(page).to have_content('Valid solicitor details are required to update and accept a Defence Request')
          within '.solicitor-details' do
            fill_in 'Full Name', with: 'Dodgy Dave'
            fill_in 'Name of firm', with: 'Innocent your honour'
          end
          click_button 'Update and Accept'

          expect(page).to have_content('A Valid DSCC number is required to update and accept a Defence Request')
          within '.solicitor-details' do
            fill_in 'Full Name', with: 'Dodgy Dave'
            fill_in 'Name of firm', with: 'Innocent your honour'
          end
          fill_in 'DSCC number', with: '123456'
          click_button 'Update and Accept'
          expect(page).to have_content('Defence Request successfully updated and marked as accepted')
        end
      end
    end

  end

  context 'Show' do
    context 'as cco' do
      before :each do
        create_role_and_login('cso')
      end
      let!(:accepted_dr) { create(:defence_request, :accepted) }

      scenario 'can not edit the expected arrival time from show page' do
        visit defence_requests_path
        within '.accepted-defence-request' do
          click_link('Show')
        end

        expect(page).to_not have_selector('.time-of-arrival')
      end
    end

    context 'as cso' do
      before :each do
        create_role_and_login('cso')
      end
      let!(:accepted_dr) { create(:defence_request, :accepted) }

      scenario 'can not edit the expected arrival time from show page' do
        visit defence_requests_path
        within '.accepted-defence-request' do
          click_link('Show')
        end

        expect(page).to_not have_selector('.time-of-arrival')
      end
    end
  end
end

def stub_solicitor_search_for_bob_smith
  body = File.open 'spec/fixtures/bob_smith_solicitor_search.json'
  stub_request(:post, "http://solicitor-search.herokuapp.com/search/?q=Bob%20Smith").
    to_return(body: body, status: 200)
end

def stub_solicitor_search_for_barry_jones
  body = File.open 'spec/fixtures/barry_jones_solicitor_search.json'
  stub_request(:post, "http://solicitor-search.herokuapp.com/search/?q=Barry%20Jones").
    to_return(body: body, status: 200)
end

def stub_solicitor_search_for_mystery_man
  body = {solicitors: [], firms: []}.to_json
  stub_request(:post, "http://solicitor-search.herokuapp.com/search/?q=Mystery%20Man").
    to_return(body: body, status: 200)
end

def an_audit_should_exist_for_the_defence_request_creation
  expect(DefenceRequest.first.audits.length).to eq 1
  audit = DefenceRequest.first.audits.first

  expect(audit.auditable_type).to eq 'DefenceRequest'
  expect(audit.action).to eq 'create'
end
