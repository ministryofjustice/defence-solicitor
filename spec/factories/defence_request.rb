FactoryGirl.define do
  now = Time.new(2001,1,1,1,1)
  twenty_one_years_ago = Time.current - 21.years

  sequence(:dscc_number_helper) do |n|
    n
  end

  generate_dscc_number = -> do
    n = FactoryGirl.sequence_by_name(:dscc_number_helper).next
    prefix = (created_at || Time.now).strftime("%y%m")
    return "%s%05d%s" % [prefix, n, DsccNumberGenerator::DEFAULT_SUFFIX]
  end

  factory :defence_request do
    sequence(:detainee_name) { |n| "detainee_name-#{n}" }
    gender "male"
    date_of_birth twenty_one_years_ago
    custody_number "AN14574637587"
    offences "Theft"
    time_of_arrival now
    sequence(:comments) { |n| "commenty-comments-are here: #{n}" }
    adult [nil, true, false].sample
    appropriate_adult false
    fit_for_interview true
    interpreter_required false
    detainee_address_not_given "1"
    time_of_arrest now
    time_of_detention_authorised now
    circumstances_of_arrest "Caught with their hand in the cookie jar"
    custody_suite_uid { SecureRandom.uuid }
  end

  trait :draft do
    state "draft"
  end

  trait :queued do
    state "queued"
  end

  trait :acknowledged do
    state "acknowledged"
    association :cco, factory: :cco_user
  end

  trait :with_solicitor do
    association :solicitor, factory: :solicitor_user
  end

  trait :with_dscc_number do
    dscc_number &generate_dscc_number
  end

  trait :with_arrest_time do
    time_of_arrest DateTime.current
  end

  trait :with_detention_authorised_time do
    time_of_detention_authorised DateTime.current
  end

  trait :accepted do
    state "accepted"
    dscc_number &generate_dscc_number
    association :solicitor, factory: :solicitor_user
  end

  trait :aborted do
    dscc_number &generate_dscc_number
    reason_aborted "This has been closed for a reason."
    state "aborted"
  end

  trait :completed do
    state "completed"
  end

  trait :appropriate_adult do
    appropriate_adult true
    appropriate_adult_reason "detainee_juvenile"
  end

  trait :interview_start_time do
    interview_start_time now
  end

  trait :with_detainee_address do
    detainee_address_not_given "0"
    detainee_address "House on the Hill, Letsby Avenue, Right up my street, London, Greater London, XX1 1XX"
  end

  trait :with_investigating_officer do
    investigating_officer_name "Dave Mc.Copper"
    investigating_officer_contact_number "0207 111 0000"
  end

  trait :unfit_for_interview do
    fit_for_interview false
    unfit_for_interview_reason "Drunk as a skunk"
  end

  trait :with_interpreter_required do
    interpreter_required true
    interpreter_type "ENGLISH - GERMAN"
  end
end
