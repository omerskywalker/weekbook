module UsersHelper
  def avatar_for(user, size: 80)
    if user.avatar.attached?
      image_tag user.avatar, class: "rounded-full object-cover", width: size, height: size
    else
      image_tag "default-avatar.png", width: size, height: size, class: "rounded-full"
    end
  end
end