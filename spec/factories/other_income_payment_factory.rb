FactoryBot.define do
  factory :other_income_payment do
    other_income_source
    payment_date { Faker::Date.between(from: 3.months.ago, to: Date.today) }
    amount { Faker::Number.decimal(l_digits: 3, r_digits: 2) }
  end
end
