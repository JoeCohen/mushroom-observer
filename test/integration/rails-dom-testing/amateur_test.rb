# frozen_string_literal: true

require("test_helper")

# Test typical sessions of amateur user who just posts the occasional comment,
# observations, or votes.
class AmateurTest < IntegrationTestCase
  # -------------------------------
  #  Test basic login heuristics.
  # -------------------------------

  def test_login
    # Start at index.
    get("/")

    # Login.
    click_mo_link(label: "Login", in: :left_panel)
    assert_template("account/login/new")

    # Try to login without a password.
    open_form do |form|
      form.assert_value("login", "")
      form.assert_value("password", "")
      form.assert_checked("remember_me")
      form.change("login", "rolf")
      form.submit("Login")
    end
    assert_template("account/login/new")
    assert_flash_text(/unsuccessful/i)

    # Try again with incorrect password.
    open_form do |form|
      form.assert_value("login", "rolf")
      form.assert_value("password", "")
      form.assert_checked("remember_me")
      form.change("password", "boguspassword")
      form.uncheck("remember_me")
      form.submit("Login")
    end
    assert_template("account/login/new")
    assert_flash_text(/unsuccessful/i)

    # Try yet again with correct password.
    open_form do |form|
      form.assert_value("login", "rolf")
      form.assert_value("password", "")
      form.assert_unchecked("remember_me")
      form.change("password", "testpassword")
      form.submit("Login")
    end
    assert_template("rss_logs/index")
    assert_flash_text(/success/i)

    # This should only be accessible if logged in.
    click_mo_link(label: "Preferences", in: :left_panel)
    assert_template("account/preferences/edit")

    # Log out and try again.
    click_mo_link(label: "Logout", in: :left_panel)
    assert_template("account/login/logout")
    assert_raises(MiniTest::Assertion) do
      click_mo_link(label: "Preferences", in: :left_panel)
    end
    get("/account/preferences/edit")
    assert_template("account/login/new")
  end

  # ----------------------------
  #  Test autologin cookies.
  # ----------------------------

  def test_autologin
    rolf_cookies = get_cookies(rolf, true)
    mary_cookies = get_cookies(mary, true)
    dick_cookies = get_cookies(dick, false)
    try_autologin(rolf_cookies, rolf)
    try_autologin(mary_cookies, mary)
    try_autologin(dick_cookies, false)
  end

  def get_cookies(user, autologin)
    sess = open_session
    sess.login(user, "testpassword", autologin)
    result = sess.cookies.dup
    if autologin
      assert_match(/^#{user.id}/, result["mo_user"])
    else
      assert_equal("", result["mo_user"].to_s)
    end
    result
  end

  def try_autologin(cookies, user)
    sess = open_session
    sess.cookies["mo_user"] = cookies["mo_user"]
    sess.get("/account/preferences/edit")
    if user
      sess.assert_match("account/preferences/edit", sess.response.body)
      sess.assert_no_match("account/login/new", sess.response.body)
      assert_users_equal(user, sess.assigns(:user))
    else
      sess.assert_no_match("account/preferences/edit", sess.response.body)
      sess.assert_match("account/login/new", sess.response.body)
    end
  end

  # ----------------------------------
  #  Test everything about comments.
  # ----------------------------------

  def test_post_comment
    obs = observations(:detailed_unknown_obs)
    # (Make sure Katrina doesn't own any comments on this observation yet.)
    assert_false(obs.comments.any? { |c| c.user == katrina })

    summary = "Test summary"
    message = "This is a big fat test!"
    message2 = "This may be _Xylaria polymorpha_, no?"

    # Start by showing the observation...
    login("katrina")
    get("/#{obs.id}")

    # (Make sure there are no edit or destroy controls on existing comments.)
    assert_select(
      "a[class*='edit_comment_'], input[class*='destroy_comment_']", false
    )

    click_mo_link(label: "Add Comment")
    assert_template("comments/new")

    # (Make sure the form is for the correct object!)
    assert_objs_equal(obs, assigns(:target))
    # (Make sure there is a tab to go back to observations/show.)
    assert_select("#right_tabs a[href='/#{obs.id}']")

    open_form(&:submit) # (submit without commenting anything)
    assert_template("comments/new")
    # (I don't care so long as it says something.)
    assert_flash_text(/\S/)

    open_form("#comment_form") do |form|
      form.change("summary", summary)
      form.change("comment", message)
      form.submit
    end
    assert_template("observations/show")
    assert_objs_equal(obs, assigns(:observation))

    com = Comment.last
    assert_equal(summary, com.summary)
    assert_equal(message, com.comment)

    # (Make sure comment shows up somewhere.)
    assert_match(summary, response.body)
    assert_match(message, response.body)
    # (Make sure there is an edit and destroy control for the new comment.)
    assert_select("a[class*='edit_comment_']", 1)
    assert_select("input[class*='destroy_comment_']", 1)

    # Try changing it.
    click_mo_link(label: /edit/i, href: /#{edit_comment_path(com.id)}/)
    assert_template("comments/edit")
    open_form("#comment_form") do |form|
      form.assert_value("summary", summary)
      form.assert_value("comment", message)
      form.change("comment", message2)
      form.submit
    end
    assert_template("observations/show")
    assert_objs_equal(obs, assigns(:observation))

    com.reload
    assert_equal(summary, com.summary)
    assert_equal(message2, com.comment)

    # (Make sure comment shows up somewhere.)
    assert_match(summary, response.body)
    assert(response.body.index(message2.tl))
    # (There should be a link in there to look up Xylaria polymorpha.)
    assert_select("a[href*=lookup_name]", 1) do |links|
      url = links.first.attributes["href"]
      assert_equal("#{MO.http_domain}/lookups/lookup_name/Xylaria+polymorpha",
                   url.value)
    end

    # I grow weary of this comment.
    click_mo_link(label: /destroy/i, href: /#{comment_path(com.id)}/)
    assert_template("observations/show")
    assert_objs_equal(obs, assigns(:observation))
    assert_nil(response.body.index(summary))
    assert_select("a[class*='edit_comment_'], input[class*='destroy_comment_']",
                  false)
    assert_nil(Comment.safe_find(com.id))
  end

  # --------------------------------------
  #  Test proposing and voting on names.
  # --------------------------------------

  def test_proposing_names
    namer_session = open_session.extend(NamerDsl)
    namer = katrina

    obs = observations(:detailed_unknown_obs)
    # (Make sure Katrina doesn't own any comments on this observation yet.)
    assert_false(obs.comments.any? { |c| c.user == namer })
    # (Make sure the name we are going to suggest doesn't exist yet.)
    text_name = "Xylaria polymorpha"
    assert_nil(Name.find_by(text_name: text_name))
    orignal_name = obs.name

    namer_session.propose_then_login(namer, obs)
    naming = namer_session.create_name(obs, text_name)

    voter_session = open_session.extend(VoterDsl)
    voter_session.login!(rolf)
    assert_not_equal(namer_session.session[:session_id],
                     voter_session.session[:session_id])
    voter_session.vote_on_name(obs, naming)
    namer_session.failed_delete(obs)
    voter_session.change_mind(obs, naming)
    namer_session.successful_delete(obs, naming, text_name, orignal_name)
  end

  def test_sessions
    rolf_session = open_session.extend(NamerDsl)
    rolf_session.login!(rolf)
    mary_session = open_session.extend(VoterDsl)
    mary_session.login!(mary)
    assert_not_equal(mary_session.session[:session_id],
                     rolf_session.session[:session_id])
  end

  # ------------------------------------------------------------------------
  #  Quick test to try to catch a bug that the functional tests can't seem
  #  to catch.  (Functional tests can survive undefined local variables in
  #  partials, but not integration tests.)
  # ------------------------------------------------------------------------

  def test_edit_image
    login("mary")
    get("/images/1/edit")
  end

  # ------------------------------------------------------------------------
  #  Tests to make sure that the proper links are rendered  on the  home page
  #  when a user is logged in.
  #  test_user_dropdown_avaiable:: tests for existence of dropdown bar & links
  #
  # ------------------------------------------------------------------------

  def test_user_dropdown_avaiable
    login("dick")
    get("/")
    assert_select("li#user_drop_down")
    links = css_select("li#user_drop_down a")
    assert_equal(links.length, 7)
  end

  # -------------------------------------------------------------------------
  #  Need integration test to make sure session and actions are all working
  #  together correctly.
  # -------------------------------------------------------------------------

  def test_thumbnail_maps
    get("/#{observations(:minimal_unknown_obs).id}")
    assert_template("observations/show")

    login("dick")
    assert_template("observations/show")
    assert_select("div.thumbnail-map", 1)
    click_mo_link(label: "Hide thumbnail map")
    assert_template("observations/show")
    assert_select("div.thumbnail-map", 0)

    get("/#{observations(:detailed_unknown_obs).id}")
    assert_template("observations/show")
    assert_select("div.thumbnail-map", 0)
  end

  # -----------------------------------------------------------------------
  #  Need intrgration test to make sure tags are being tracked and passed
  #  through redirects correctly.
  # -----------------------------------------------------------------------

  def test_language_tracking
    session = open_session.extend(UserDsl)
    session.login(mary)
    mary.locale = "el"
    I18n.with_locale(:el) do
      mary.save

      TranslationString.store_localizations(
        :el,
        { test_tag1: "test_tag1 value",
          test_tag2: "test_tag2 value",
          test_flash_redirection_title: "Testing Flash Redirection" }
      )

      session.run_test
    end
  end

  module UserDsl
    def run_test
      get("/test_pages/flash_redirection?tags=")
      click_mo_link(label: :app_edit_translations_on_page.t)
      assert_no_flash
      assert_select("span.tag", text: "test_tag1:", count: 0)
      assert_select("span.tag", text: "test_tag2:", count: 0)
      assert_select("span.tag", text: "test_flash_redirection_title:", count: 1)

      get("/test_pages/flash_redirection?tags=test_tag1,test_tag2")
      click_mo_link(label: :app_edit_translations_on_page.t)
      assert_no_flash
      assert_select("span.tag", text: "test_tag1:", count: 1)
      assert_select("span.tag", text: "test_tag2:", count: 1)
      assert_select("span.tag", text: "test_flash_redirection_title:", count: 1)
    end
  end

  # Note that this only tests non-JS vote submission.
  # Most users will have their vote sent via AJAX from naming_vote_ajax.js
  module VoterDsl
    def vote_on_name(obs, naming)
      get("/#{obs.id}")
      open_form("form#naming_vote_#{naming.id}") do |form|
        form.assert_value("vote_value", /no opinion/i)
        form.select("vote_value", /call it that/i)
        form.assert_value("vote_value", "3.0")
        form.submit("Cast Vote")
      end
      # assert_template("observations/show")
      assert_match(/call it that/i, response.body)
    end

    def change_mind(obs, naming)
      # "change_mind response.body".print_thing(response.body)
      get("/#{obs.id}")
      open_form("form#naming_vote_#{naming.id}") do |form|
        form.select("vote_value", /as if!/i)
        form.submit(:show_namings_cast.l)
      end
    end
  end

  module NamerDsl
    def propose_then_login(namer, obs)
      get("/#{obs.id}")
      assert_template("observations/show")
      click_mo_link(label: /login/i)
      assert_template("account/login/new")
      open_form do |form|
        form.change("login", namer.login)
        form.change("password", "testpassword")
        form.change("remember_me", true)
        form.submit("Login")
      end
      assert_select(
        "a[class*='edit_naming_'], input[class*='destroy_naming_']",
        false
      )
      click_mo_link(label: /propose.*name/i)
    end

    def create_name(obs, text_name)
      assert_template("observations/namings/new")
      # (Make sure the form is for the correct object!)
      assert_objs_equal(obs, assigns(:params).observation)
      # (Make sure there is a tab to go back to observations/show.)
      assert_select("#right_tabs a[href='/#{obs.id}']")

      open_form do |form|
        form.assert_value("naming_name", "")
        form.assert_value("naming_vote_value", "")
        form.assert_unchecked("naming_reasons_1_check")
        form.assert_unchecked("naming_reasons_2_check")
        form.assert_unchecked("naming_reasons_3_check")
        form.assert_unchecked("naming_reasons_4_check")
        form.submit
      end
      assert_template("observations/namings/new")
      # (I don't care so long as it says something.)
      assert_flash_text(/\S/)

      open_form do |form|
        form.change("naming_name", text_name)
        form.submit
      end
      assert_template("observations/namings/new")
      assert_select("div.alert-warning") do |elems|
        assert(elems.any? do |e|
                 /MO does not recognize the name.*#{text_name}/ =~ e.to_s
               end,
               "Expected error about name not existing yet.")
      end

      open_form do |form|
        form.assert_value("naming_name", text_name)
        form.assert_unchecked("naming_reasons_1_check")
        form.assert_unchecked("naming_reasons_2_check")
        form.assert_unchecked("naming_reasons_3_check")
        form.assert_unchecked("naming_reasons_4_check")
        form.select(/vote/, /call it that/i)
        form.submit
      end
      assert_template("observations/show")
      assert_flash_text(/success/i)
      assert_objs_equal(obs, assigns(:observation))

      obs.reload
      name = Name.find_by(text_name: text_name)
      naming = Naming.last
      assert_names_equal(name, naming.name)
      assert_names_equal(name, obs.name)
      assert_equal("", name.author.to_s)

      # (Make sure naming shows up somewhere.)
      assert_match(text_name, response.body)
      # (Make sure there is an edit and destroy control for the new naming.)
      # (Now one: same for wide-screen as for mobile.)
      assert_select("a[href*='#{edit_naming_path(naming.id)}']", 1)
      assert_select("input.destroy_naming_link_#{naming.id}", 1)

      # Try changing it.
      author = "(Pers.) Grev."
      reason = "Test reason."
      click_mo_link(label: /edit/i, href: /#{edit_naming_path(naming.id)}/)
      assert_template("observations/namings/edit")
      open_form do |form|
        form.assert_value("naming_name", text_name)
        form.assert_checked("naming_reasons_1_check")
        form.uncheck("naming_reasons_1_check")
        form.change("naming_name", "#{text_name} #{author}")
        form.check("naming_reasons_2_check")
        form.change("naming_reasons_2_notes", reason)
        form.select("naming_vote_value", /call it that/i)
        form.submit
      end
      assert_template("observations/show")
      assert_objs_equal(obs, assigns(:observation))

      obs.reload
      name.reload
      naming.reload
      assert_equal(author, name.author)
      assert_names_equal(name, naming.name)
      assert_names_equal(name, obs.name)

      # (Make sure author shows up somewhere.)
      assert_match(author, response.body)
      # (Make sure reason shows up, too.)
      assert_match(reason, response.body)

      click_mo_link(label: /edit/i, href: /#{edit_naming_path(naming.id)}/)
      assert_template("observations/namings/edit")
      open_form do |form|
        form.assert_value("naming_name", "#{text_name} #{author}")
        form.assert_unchecked("naming_reasons_1_check")
        form.assert_value("naming_reasons_1_notes", "")
        form.assert_checked("naming_reasons_2_check")
        form.assert_value("naming_reasons_2_notes", reason)
        form.assert_unchecked("naming_reasons_3_check")
        form.assert_value("naming_reasons_3_notes", "")
      end
      click_mo_link(label: /cancel.*show/i)
      naming
    end

    def failed_delete(_obs)
      click_mo_link(label: /destroy/i, href: /namings/)
      assert_flash_text(/sorry/i)
    end

    def successful_delete(obs, naming, text_name, original_name)
      click_mo_link(label: /destroy/i, href: /#{naming_path(naming.id)}/)
      assert_template("observations/show")
      assert_objs_equal(obs, assigns(:observation))
      assert_flash_text(/success/i)

      obs.reload
      assert_names_equal(original_name, obs.name)
      assert_nil(Naming.safe_find(naming.id))
      assert_no_match(text_name, response.body)
    end
  end
end
