class ApiKey < ActiveRecord::Base
  belongs_to :user
  before_create :provide_defaults

  KEY_LENGTH = 32

  def provide_defaults
    self.created ||= Time.now
    self.last_used ||= nil
    self.num_uses ||= 0
    self.user_id ||= User.current_id
    self.key ||= self.class.new_key
    self.notes ||= ''
  end

  def touch!
    update_attributes!(
      :last_used => Time.now,
      :num_uses => num_uses + 1
    )
  end 

  def self.new_key
    result = String.random(KEY_LENGTH) 
    while find_by_key(result)
      key = String.random(KEY_LENGTH) 
    end
    return result
  end

  def validate
    other = self.class.find_by_key(key)
    if other and other.id != self.id
      # This should never happen.
      errors.add(:key, 'api keys must be unique')
    end
    if notes.blank?
      errors.add(:notes, :account_api_keys_no_notes.t)
    end
  end
end