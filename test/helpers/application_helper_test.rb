require "test_helper"

# test the methods in application_helper
class ApplicationHelperTest < ActionView::TestCase
  def test_textile_markup_should_be_escaped
  	textile = "**Bold**"
  	escaped = "&lt;div class=&quot;textile&quot;&gt;&lt;p&gt;&lt;b&gt;Bold&lt;/b&gt;&lt;/p&gt;&lt;/div&gt;"
		assert_equal escaped, escape_html(textile.tpl)
  end

  def test_observation_title
    # observation with 2 specimens should display: name, author, id, 2 specimens
    observation = Observation.find(3)
    name = observation.name
    specimens = observation.specimens
    title = observation_title(observation)

    assert_match(/Observation/, title)
    assert_match(/#{name.text_name}/, title)
    assert_match(/#{Regexp.escape(name.author)}/, title)
    assert_match(/#{observation.id}/, title)
    specimens.each do |specimen|
      assert_match(/#{specimen.herbarium_label}/, title)
    end

    # observation with 0 specimens should display: name, author, id, 0 specimens
    observation = Observation.find(5)
    title = observation_title(observation)

    assert(title.end_with?("(#{observation.id})"),
      "Title of specimenless Observation should end with id in parens")
  end
end
