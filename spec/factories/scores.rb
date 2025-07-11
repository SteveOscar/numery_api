# == Schema Information
#
# Table name: scores
#
#  id         :integer          not null, primary key
#  score      :integer
#  user_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :score do
    score { 1 }
    user { nil }
  end
end
