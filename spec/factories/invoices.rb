FactoryGirl.define do
  factory :invoice do
    period_start Date.today
    period_end(Date.today + 15)
    amount 150.25
    association :plan
    current true
  end

  factory :package_invoice do |i|
    period_start Date.today
    period_end(Date.today + 15)
    amount 150.25
    association :plan
    current true
  end


  factory :licensed_invoice do |i|
    period_start Date.today
    period_end(Date.today + 15)
    amount 150.25
    current true
  end
end
