# == Schema Information
#
# Table name: parkings
#
#  id           :uuid             not null, primary key
#  name         :string           not null
#  phone_number :string
#  status       :string           default("available"), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :uuid             not null
#
# Indexes
#
#  index_parkings_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Parking < ApplicationRecord
  extend Enumerize

  belongs_to :user

  enumerize :status, in: %i[available full], default: :available, predicates: true, scope: true

  before_validation :normalize_phone_number

  validates :name, presence: true
  validates :status, presence: true
  validates :phone_number, format: { with: /\A\d*\z/, message: "は数字のみで入力してください" }, allow_blank: true

  def status_text
    status_text = status&.text
    status_text.presence || status
  end

  private

  def normalize_phone_number
    self.phone_number = phone_number.gsub(/-/, "") if phone_number.present?
  end
end
