class InviteRequest < ActiveRecord::Base
  belongs_to :tournament
  belongs_to :user
  belongs_to :invite

  def completed?
    invite.present?
  end
end
