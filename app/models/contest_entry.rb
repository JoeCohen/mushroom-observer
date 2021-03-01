# frozen_string_literal: true

class ContestEntry < AbstractModel
  belongs_to :image

  def title
    "#{:CONTEST_ENTRY.t}: #{copyright_holder}"
  end

  def copyright_holder
    image&.copyright_holder || ""
  end
end
