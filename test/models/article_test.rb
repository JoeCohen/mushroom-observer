require "test_helper"

class ArticleTest < UnitTestCase
  def test_can_edit
    article = articles(:premier_article)
    assert(article.can_edit?(users(:article_writer)))
    refute(article.can_edit?(users(:zero_user)))
  end
end
