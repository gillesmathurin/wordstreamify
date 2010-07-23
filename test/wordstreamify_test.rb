require 'test_helper'

class WordstreamifyTest < ActiveSupport::TestCase
  load_schema
  
  class Keyword < ActiveRecord::Base        
  end
  
  def test_schema_has_loaded_correctly
    assert_equal [], Keyword.all
  end
  
  def test_login_set_session_id
    ws_session_id = Keyword.wordstream_login('username', 'password')
    assert_match('username:', ws_session_id)
  end
  
  def test_logout_from_wordstream
    ws_session_id = Keyword.wordstream_login('username', 'password')
    assert_equal({"code"=> "OK"}, Keyword.wordstream_logout(ws_session_id) )
  end
  
  def test_get_ws_api_credits
    assert_not_nil(Keyword.get_ws_api_credits('username', 'password'))
    assert_kind_of(Fixnum, Keyword.get_ws_api_credits('username', 'password'))
  end
  
  def test_ws_api_credits
    ws_session_id = Keyword.wordstream_login('username', 'password')
    credits = Keyword.ws_api_credits(ws_session_id)
    puts credits
    assert_not_nil(credits)
  end
  
  def test_get_keywords
    #### with unsufficient credits ####
    result = Keyword.get_keywords('username', 'password', 'basket-ball')
    assert_kind_of(Array , result)
    assert(result.size > 0 )
    assert(result.size <= 50)  
  end
  
  def test_get_keyword_niches
    # TODO    
  end
  
  def test_get_keyword_volumes
    # TODO
  end
  
  def test_get_question_keywords
    # TODO
  end
  
  def test_get_related_keywords
    # TODO
  end
end
