# Wordstreamify
require "rubygems"
require "net/http"
require "net/https"
require "uri"
require "json/ext"

module Wordstreamify
  
  def self.included(receiver)
    receiver.extend ClassMethods
    receiver.send :include, InstanceMethods
  end
      
  module ClassMethods

    # Login to Wordstream with the given credentials
    # If successful, returns the 'OK' return code and a valid session_id useful for future API requests
    def wordstream_login(username, password)
      url = URI.parse('https://api.wordstream.com/authentication/login?')
      http = https_object(url, 443, true)
      request = post_request(url, {'username' => username, 'password' => password})
      begin
        response = send_request(http, request)
        parsed_response = JSON.parse(response.body)
        if parsed_response["code"] == "OK"
          ws_session_id = parsed_response["data"]["session_id"]
          return ws_session_id
        else
          return false
        end
      rescue Exception => e
        return false
      end
    end
    
    # Logout from Wordstream, returns the expired session_id and the 'OK' return code
    def wordstream_logout(session_id)
      url = URI.parse('https://api.wordstream.com/authentication/logout?')
      http = https_object(url, 443, true)
      req = post_request(url, {'session_id' => session_id})
      begin
        response = JSON.parse(send_request(http, req).body)
      rescue Exception => e
        return nil
      end
    end
    
    # Returns the remaining api credits for a Wordstream account as an integer
    def get_ws_api_credits(username, password)
      ws_session_id = self.wordstream_login(username, password)
      url = URI.parse('https://api.wordstream.com/authentication/get_api_credits?')
      http = https_object(url, 443, true)
      req = post_request(url, {'session_id' => ws_session_id})
      begin
        response = send_request(http, req)
        parsed_response = JSON.parse(response.body)
        return parsed_response["data"]["remaining_monthly_credits"]
      rescue Exception => e
        return nil
      end
    end
    
    # Same as get_ws_api_credits but you need to pass a valid session_id as argument
    def ws_api_credits(session_id)
      url = URI.parse('https://api.wordstream.com/authentication/get_api_credits?')
      http = https_object(url, 443, true)
      req = post_request(url, {'session_id' => session_id})

      begin
        response = send_request(http, req)
        parsed_response = JSON.parse(response.body)
        return parsed_response["data"]["remaining_monthly_credits"]
      rescue Exception => e
        return nil
      end
    end
    
    # Suggests a set of keywords from an input keyword.
    # Return an Array of keyword suggestions string
    def get_keywords(username, password, seed, max_results=50)
      ws_session_id = self.wordstream_login(username, password)
      api_credits = self.ws_api_credits(ws_session_id)
      url = URI.parse('https://api.wordstream.com/keywordtool/get_keywords?')
      keywords = []
      
      if ( !api_credits.nil? && api_credits >= 1 )
        http = https_object(url, 443, true)
        request = post_request(url, {'seeds' => seed, 'max_results' => max_results, 'session_id' => ws_session_id})
        begin
          response = send_request(http, request)
          parsed_response = JSON.parse(response.body)
          if (parsed_response["code"] == 'OK')
            parsed_response["data"].each do |array|
              keywords << array[0]
            end
            self.wordstream_logout(ws_session_id)
            return keywords
          else
            return parsed_response["code"]
          end
        rescue Exception => e
          return ["An unexpected error occured"]
        end
      else
        return ["INSUFFICIENT_CREDITS to search for keywords"]
      end       
    end    
    
    # Suggests a set of keyword niche groups and their associated keywords based on a set of input seed terms.
    # Returns an Array of keyword and relative_volume arrays
    def get_keyword_niches(username, password, seeds, max_niches=50)
      ws_session_id = self.wordstream_login(username, password)
      api_credits = self.ws_api_credits(ws_session_id)
      url = URI.parse('https://api.wordstream.com/keywordtool/get_keyword_niches?')
      seeds = seeds.gsub(/[ ]/, '\n')
      
      if (!api_credits.nil? && api_credits >=25 )
        http = https_object(url, 443, true)
        request = post_request(url, {'seeds' => seeds, 'max_results' => max_niches, 'session_id' => ws_session_id})
        begin
          response = send_request(http, request)
          parsed_response = JSON.parse(response.body)
          if parsed_response["code"] == 'OK'
            self.wordstream_logout(ws_session_id)
            # Get keywords from seeds
            kwniches_arr = []
            for grouping in parsed_response["data"]["groupings"]
              for match in grouping['matches']
                kwniches_arr << [ parsed_response['data']['keywords'][match][0], parsed_response['data']['keywords'][match][1] ] 
              end
            end
            return kwniches_arr
            # return parsed_response["data"]
          else
            return parsed_response["code"]
          end
        rescue Exception => e
          return false
        end        
      else
        return ["INSUFFICIENT_CREDITS to search for keywords"]
      end            
    end
    
    # Provides relative volume for a set of input keywords
    # Return An array of keyword, volume pairs [[keyword, volume], [keyword, volume] ... [keyword, volume]]
    def get_keyword_volumes(username, password, seeds)
      ws_session_id = self.wordstream_login(username, password)
      api_credits = self.ws_api_credits(ws_session_id)
      url = URI.parse('https://api.wordstream.com/keywordtool/get_keyword_volumes?')
      seeds = seeds.gsub(/[ ]/, '\n')
      
      if (!api_credits.nil? && api_credits >= 1)    
        http = https_object(url, 443, true)
        request = post_request(url, {'seeds' => seeds, 'session_id' => ws_session_id})
        begin
          parsed_response = JSON.parse(send_request(http, request))
          if parsed_response['code'] == 'OK'
            self.wordstream_logout(ws_session_id)
            return parsed_response['data']
          else
            return parsed_response['code']
          end
        rescue Exception => e
          return false
        end        
      else
        return ["INSUFFICIENT_CREDITS to search for keywords"]  
      end  
    end
    
    # Suggests a set of question keywords from an input keyword
    # Return An array of keyword, volume pairs [[keyword, volume], [keyword, volume] ... [keyword, volume]]
    def get_question_keywords(username, password, seeds, max_results=50)
      ws_session_id = self.wordstream_login(username, password)
      api_credits = self.ws_api_credits(ws_session_id)
      url = URI.parse('https://api.wordstream.com/keywordtool/get_question_keywords?')
      seeds = seeds.gsub(/[ ]/, '\n')
      
      if (!api_credits.nil? && api_credits >= 10)    
        http = https_object(url, 443, true)
        request = post_request(url, {'seeds' => seeds, 'max_results' => max_results, 'session_id' => ws_session_id})
        begin
          parsed_response = JSON.parse(send_request(http, request))
          if parsed_response['code'] == 'OK'
            self.wordstream_logout(ws_session_id)
            return parsed_response['data']
          else
            return parsed_response['code']
          end
        rescue Exception => e
          return false
        end        
      else
        return ["INSUFFICIENT_CREDITS to search for keywords"]  
      end     
    end
    
    #	Suggests a set of keywords from an input keyword
    # Return An array of keywords [keyword, keyword, ... keyword]
    def get_related_keywords(username, password, seeds, max_results=50)
      ws_session_id = self.wordstream_login(username, password)
      api_credits = self.ws_api_credits(ws_session_id)
      url = URI.parse('https://api.wordstream.com/keywordtool/get_related_keywords?')
      seeds = seeds.gsub(/[ ]/, '\n')
      
      if (!api_credits.nil? && api_credits >= 25)    
        http = https_object(url, 443, true)
        request = post_request(url, {'seeds' => seeds, 'max_results' => max_results, 'session_id' => ws_session_id})
        begin
          parsed_response = JSON.parse(send_request(http, request))
          if parsed_response['code'] == 'OK'
            self.wordstream_logout(ws_session_id)
            return parsed_response['data']
          else
            return parsed_response['code']
          end
        rescue Exception => e
          return false
        end        
      else
        return ["INSUFFICIENT_CREDITS to search for keywords"]  
      end    
    end
    
    protected
    
    # Make a new Net::HTTP(s) Object to be used to send request with the given url and port
    def https_object(url, port, ssl=true)
      http = Net::HTTP.new(url.host, port)
      http.use_ssl = ssl
      http    
    end
    
    # Build a Net::HTTP POST request with the given url and post datas 
    def post_request(url, hash={})
      req = Net::HTTP::Post.new(url.path)
      req.set_form_data(hash)
      req    
    end
    
    # Send the request and returned its response
    def send_request(http_object, request)
      http_object.start do
        http_object.request(request)
      end    
    end
  end
  
  module InstanceMethods    
  end
end