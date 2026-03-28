# frozen_string_literal: true

module PhoneUtils
  # Normalize to E.164 format (+1XXXXXXXXXX for US numbers)
  # Accepts: "555-867-5309", "(555) 867-5309", "5558675309", "+15558675309"
  def self.normalize(number)
    return nil if number.blank?

    digits = number.gsub(/\D/, '')
    # Assume US if 10 digits
    digits = "1#{digits}" if digits.length == 10
    "+#{digits}"
  end
end
