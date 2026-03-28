# frozen_string_literal: true

class DigestMailer < ApplicationMailer
  def new_digest(follower, digest)
    @follower = follower
    @digest = digest
    @author = digest.user

    mail(
      to: follower.email,
      subject: "#{@author.name_for_display} published their Week #{@digest.week_number} digest"
    )
  end
end
