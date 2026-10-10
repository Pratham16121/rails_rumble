require "test_helper"

class AvatarHelperTest < ActionView::TestCase
  test "a nickname always gets the same avatar, ignoring case" do
    assert_equal avatar_for(QuizParticipant.new(nickname: "Ada")), avatar_for(QuizParticipant.new(nickname: "ada"))
  end

  test "different nicknames get different avatars" do
    avatars = %w[ Ada Grace Linus Margaret Alan Barbara ].map { |nickname| avatar_for(QuizParticipant.new(nickname: nickname)) }

    assert_operator avatars.uniq.size, :>=, 4
    assert avatars.all? { |svg| svg.start_with?('<svg class="avatar"') }
  end
end
