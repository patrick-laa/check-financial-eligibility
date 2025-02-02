FactoryBot.define do
  factory :assessment do
    sequence(:client_reference_id) { |n| sprintf("CLIENT-REF-%<number>04d", number: n) }
    remote_ip { Faker::Internet.ip_v4_address }
    submission_date { Date.current }
    version { "5" }
    transient do
      # the proceedings transient is an array of arrays, each item comprising a proceeding type code and it's associated client involvement type,
      # e.g. [ ['DA003', 'A'], ['SE014', 'Z']]
      proceedings { [%w[DA003 A]] }

      # use :with_child_dependants: 2 to create 2 children for the assessment
      with_child_dependants { 0 }
    end

    after(:create) do |record, evaluator|
      # create proceeding types if specified
      evaluator.proceedings.each do |proceeding|
        ptc, cit = proceeding
        unlimited = ptc.match?(/^DA/) && cit == "A"
        giu = unlimited ? 999_999_999_999 : 2657.0
        diu = unlimited ? 999_999_999_999 : 733.0
        capu = unlimited ? 999_999_999_999 : 8_000.0
        pt_rec = build :proceeding_type,
                       ccms_code: ptc,
                       client_involvement_type: cit,
                       gross_income_upper_threshold: giu,
                       disposable_income_upper_threshold: diu,
                       capital_upper_threshold: capu
        record.proceeding_types << pt_rec
      end

      # create child dependants if specified
      if evaluator.with_child_dependants > 0
        evaluator.with_child_dependants.times do
          create :dependant, :child_relative, assessment: record
        end
      end

      record.save!
    end

    trait :with_applicant do
      applicant { create :applicant, :under_pensionable_age }
    end

    trait :with_passported_applicant do
      applicant { create :applicant, :with_qualifying_benefits }
    end

    trait :with_non_passported_applicant do
      applicant { create :applicant, :without_qualifying_benefits }
    end

    trait :with_applicant_over_pensionable_age do
      applicant { create :applicant, :over_pensionable_age }
    end

    trait :with_disposable_income_summary do
      after(:create) do |assessment|
        create :disposable_income_summary, assessment:
      end
    end

    trait :with_disposable_income_summary_and_eligibilities do
      after(:create) do |assessment|
        dis = create :disposable_income_summary, assessment: assessment
        assessment.proceeding_type_codes.each do |ptc|
          create :disposable_income_eligibility, disposable_income_summary: dis, proceeding_type_code: ptc
        end
      end
    end

    trait :with_capital_summary do
      after(:create) do |assessment|
        create :capital_summary, assessment:
      end
    end

    trait :with_capital_summary_and_eligibilities do
      after(:create) do |assessment|
        capsum = create :capital_summary, assessment: assessment
        assessment.proceeding_type_codes.each do |ptc|
          create :capital_eligibility, capital_summary: capsum, proceeding_type_code: ptc
        end
      end
    end

    trait :with_gross_income_summary do
      after(:create) do |assessment|
        create :gross_income_summary, assessment:
      end
    end

    trait :with_gross_income_summary_and_eligibilities do
      after(:create) do |assessment|
        gis = create :gross_income_summary, assessment: assessment
        assessment.proceeding_type_codes.each do |ptc|
          create :gross_income_eligibility, gross_income_summary: gis, proceeding_type_code: ptc
        end
      end
    end

    trait :with_gross_income_summary_and_records do
      after(:create) do |assessment|
        create :gross_income_summary, :with_all_records, assessment:
      end
    end

    trait :with_gross_income_summary_and_employment do
      after(:create) do |assessment|
        create :gross_income_summary, :with_employment, assessment:
      end
    end

    # NOTE: this ends up creating two assessments because the :with_non_passported_applicant trait
    # creates one too
    #
    trait :with_everything do
      with_non_passported_applicant
      after(:create) do |assessment|
        create :gross_income_summary, :with_everything, assessment: assessment
        create :disposable_income_summary, :with_everything, assessment: assessment
        create :capital_summary, :with_everything, assessment:
      end
    end

    trait :passported do
      with_passported_applicant
      after(:create) do |assessment|
        create :capital_summary, :with_everything, :with_eligibilities, assessment:
      end
    end

    trait :with_eligibilities do
      after(:create) do |assessment|
        if assessment.capital_summary
          assessment.proceeding_type_codes.each do |ptc|
            assessment.capital_summary.eligibilities << create(:capital_eligibility, proceeding_type_code: ptc)
          end
        end

        if assessment.gross_income_summary
          assessment.proceeding_type_codes.each do |ptc|
            assessment.gross_income_summary.eligibilities << create(:gross_income_eligibility, proceeding_type_code: ptc)
          end
        end

        if assessment.disposable_income_summary
          assessment.proceeding_type_codes.each do |ptc|
            assessment.disposable_income_summary.eligibilities << create(:disposable_income_eligibility, proceeding_type_code: ptc)
          end
        end

        assessment.proceeding_type_codes.each do |ptc|
          assessment.eligibilities << create(:assessment_eligibility, proceeding_type_code: ptc)
        end
      end
    end
  end
end
