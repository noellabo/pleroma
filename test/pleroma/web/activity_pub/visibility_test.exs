# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.ActivityPub.VisibilityTest do
  use Pleroma.DataCase, async: true

  alias Pleroma.Activity
  alias Pleroma.Object
  alias Pleroma.Web.ActivityPub.Visibility
  alias Pleroma.Web.CommonAPI
  import Pleroma.Factory

  setup do
    user = insert(:user)
    mentioned = insert(:user)
    following = insert(:user)
    unrelated = insert(:user)
    remote = insert(:user, local: false)
    {:ok, following, user} = Pleroma.User.follow(following, user)
    {:ok, list} = Pleroma.List.create("foo", user)

    Pleroma.List.follow(list, unrelated)

    {:ok, public} =
      CommonAPI.post(user, %{status: "@#{mentioned.nickname}", visibility: "public"})

    {:ok, private} =
      CommonAPI.post(user, %{status: "@#{mentioned.nickname}", visibility: "private"})

    {:ok, direct} =
      CommonAPI.post(user, %{status: "@#{mentioned.nickname}", visibility: "direct"})

    {:ok, unlisted} =
      CommonAPI.post(user, %{status: "@#{mentioned.nickname}", visibility: "unlisted"})

    {:ok, local} = CommonAPI.post(user, %{status: "@#{mentioned.nickname}", visibility: "local"})

    {:ok, list} =
      CommonAPI.post(user, %{
        status: "@#{mentioned.nickname}",
        visibility: "list:#{list.id}"
      })

    %{
      public: public,
      private: private,
      direct: direct,
      unlisted: unlisted,
      user: user,
      mentioned: mentioned,
      following: following,
      unrelated: unrelated,
      list: list,
      local: local,
      remote: remote
    }
  end

  test "is_direct?", %{
    public: public,
    private: private,
    direct: direct,
    unlisted: unlisted,
    list: list,
    local: local
  } do
    assert Visibility.is_direct?(direct)
    refute Visibility.is_direct?(public)
    refute Visibility.is_direct?(private)
    refute Visibility.is_direct?(unlisted)
    assert Visibility.is_direct?(list)
    refute Visibility.is_direct?(local)
  end

  test "is_public?", %{
    public: public,
    private: private,
    direct: direct,
    unlisted: unlisted,
    local: local,
    list: list
  } do
    refute Visibility.is_public?(direct)
    assert Visibility.is_public?(public)
    refute Visibility.is_public?(private)
    assert Visibility.is_public?(unlisted)
    assert Visibility.is_public?(local)
    refute Visibility.is_public?(list)
  end

  test "is_private?", %{
    public: public,
    private: private,
    direct: direct,
    unlisted: unlisted,
    list: list,
    local: local
  } do
    refute Visibility.is_private?(direct)
    refute Visibility.is_private?(public)
    assert Visibility.is_private?(private)
    refute Visibility.is_private?(unlisted)
    refute Visibility.is_private?(list)
    refute Visibility.is_private?(local)
  end

  test "is_list?", %{
    public: public,
    private: private,
    direct: direct,
    unlisted: unlisted,
    list: list,
    local: local
  } do
    refute Visibility.is_list?(direct)
    refute Visibility.is_list?(public)
    refute Visibility.is_list?(private)
    refute Visibility.is_list?(unlisted)
    assert Visibility.is_list?(list)
    refute Visibility.is_list?(local)
  end

  test "visible_for_user? Activity", %{
    public: public,
    private: private,
    direct: direct,
    unlisted: unlisted,
    user: user,
    mentioned: mentioned,
    following: following,
    unrelated: unrelated,
    list: list,
    local: local,
    remote: remote
  } do
    # All visible to author

    assert Visibility.visible_for_user?(public, user)
    assert Visibility.visible_for_user?(private, user)
    assert Visibility.visible_for_user?(unlisted, user)
    assert Visibility.visible_for_user?(direct, user)
    assert Visibility.visible_for_user?(list, user)
    assert Visibility.visible_for_user?(local, user)

    # All visible to a mentioned user

    assert Visibility.visible_for_user?(public, mentioned)
    assert Visibility.visible_for_user?(private, mentioned)
    assert Visibility.visible_for_user?(unlisted, mentioned)
    assert Visibility.visible_for_user?(direct, mentioned)
    assert Visibility.visible_for_user?(list, mentioned)
    assert Visibility.visible_for_user?(local, mentioned)

    # DM not visible for just follower

    assert Visibility.visible_for_user?(public, following)
    assert Visibility.visible_for_user?(private, following)
    assert Visibility.visible_for_user?(unlisted, following)
    refute Visibility.visible_for_user?(direct, following)
    refute Visibility.visible_for_user?(list, following)
    assert Visibility.visible_for_user?(local, following)

    # Public and unlisted visible for unrelated user

    assert Visibility.visible_for_user?(public, unrelated)
    assert Visibility.visible_for_user?(unlisted, unrelated)
    refute Visibility.visible_for_user?(private, unrelated)
    refute Visibility.visible_for_user?(direct, unrelated)
    assert Visibility.visible_for_user?(local, unrelated)

    # Public and unlisted visible for unauthenticated

    assert Visibility.visible_for_user?(public, nil)
    assert Visibility.visible_for_user?(unlisted, nil)
    refute Visibility.visible_for_user?(private, nil)
    refute Visibility.visible_for_user?(direct, nil)
    refute Visibility.visible_for_user?(local, nil)

    # Visible for a list member
    assert Visibility.visible_for_user?(list, unrelated)

    # Local not visible to remote user
    refute Visibility.visible_for_user?(local, remote)
  end

  test "visible_for_user? Object", %{
    public: public,
    private: private,
    direct: direct,
    unlisted: unlisted,
    user: user,
    mentioned: mentioned,
    following: following,
    unrelated: unrelated,
    list: list,
    local: local,
    remote: remote
  } do
    public = Object.normalize(public)
    private = Object.normalize(private)
    unlisted = Object.normalize(unlisted)
    direct = Object.normalize(direct)
    list = Object.normalize(list)
    local = Object.normalize(local)

    # All visible to author

    assert Visibility.visible_for_user?(public, user)
    assert Visibility.visible_for_user?(private, user)
    assert Visibility.visible_for_user?(unlisted, user)
    assert Visibility.visible_for_user?(direct, user)
    assert Visibility.visible_for_user?(list, user)

    # All visible to a mentioned user

    assert Visibility.visible_for_user?(public, mentioned)
    assert Visibility.visible_for_user?(private, mentioned)
    assert Visibility.visible_for_user?(unlisted, mentioned)
    assert Visibility.visible_for_user?(direct, mentioned)
    assert Visibility.visible_for_user?(list, mentioned)

    # DM not visible for just follower

    assert Visibility.visible_for_user?(public, following)
    assert Visibility.visible_for_user?(private, following)
    assert Visibility.visible_for_user?(unlisted, following)
    refute Visibility.visible_for_user?(direct, following)
    refute Visibility.visible_for_user?(list, following)

    # Public and unlisted visible for unrelated user

    assert Visibility.visible_for_user?(public, unrelated)
    assert Visibility.visible_for_user?(unlisted, unrelated)
    refute Visibility.visible_for_user?(private, unrelated)
    refute Visibility.visible_for_user?(direct, unrelated)

    # Public and unlisted visible for unauthenticated

    assert Visibility.visible_for_user?(public, nil)
    assert Visibility.visible_for_user?(unlisted, nil)
    refute Visibility.visible_for_user?(private, nil)
    refute Visibility.visible_for_user?(direct, nil)
    refute Visibility.visible_for_user?(local, nil)

    # Local posts to remote
    refute Visibility.visible_for_user?(local, remote)
    # Visible for a list member
    # assert Visibility.visible_for_user?(list, unrelated)
  end

  test "doesn't die when the user doesn't exist",
       %{
         direct: direct,
         user: user
       } do
    Repo.delete(user)
    Pleroma.User.invalidate_cache(user)
    refute Visibility.is_private?(direct)
  end

  test "get_visibility", %{
    public: public,
    private: private,
    direct: direct,
    unlisted: unlisted,
    list: list
  } do
    assert Visibility.get_visibility(public) == "public"
    assert Visibility.get_visibility(private) == "private"
    assert Visibility.get_visibility(direct) == "direct"
    assert Visibility.get_visibility(unlisted) == "unlisted"
    assert Visibility.get_visibility(list) == "list"
  end

  test "get_visibility with directMessage flag" do
    assert Visibility.get_visibility(%{data: %{"directMessage" => true}}) == "direct"
  end

  test "get_visibility with listMessage flag" do
    assert Visibility.get_visibility(%{data: %{"listMessage" => ""}}) == "list"
  end

  describe "entire_thread_visible_for_user?/2" do
    test "returns false if not found activity", %{user: user} do
      refute Visibility.entire_thread_visible_for_user?(%Activity{}, user)
    end

    test "returns true if activity hasn't 'Create' type", %{user: user} do
      activity = insert(:like_activity)
      assert Visibility.entire_thread_visible_for_user?(activity, user)
    end

    test "returns false when invalid recipients", %{user: user} do
      author = insert(:user)

      activity =
        insert(:note_activity,
          note:
            insert(:note,
              user: author,
              data: %{"to" => ["test-user"]}
            )
        )

      refute Visibility.entire_thread_visible_for_user?(activity, user)
    end

    test "returns true if user following to author" do
      author = insert(:user)
      user = insert(:user)
      Pleroma.User.follow(user, author)

      activity =
        insert(:note_activity,
          note:
            insert(:note,
              user: author,
              data: %{"to" => [user.ap_id]}
            )
        )

      assert Visibility.entire_thread_visible_for_user?(activity, user)
    end
  end
end
