require 'pry'
require 'json'
require './lib/oauth_access_token_preparer.rb'

class TwitterApiClient
  include OauthAccessTokenPreparer

  BASE_URI = 'https://api.twitter.com/1.1'

  @@token_preparer = OauthAccessTokenPreparer

  def get(twitter_user_name, count)
    handle_timeouts do
      response = access_token.request(:get, url(twitter_user_name, count))
      handle_response(response)
    end 
  end

  def self.set_token_preparer(token_preparer)
    @@token_preparer = token_preparer
  end

  private

    def handle_response(response)
      if response.code == '200'
        print_tweets(response)
      else
        JSON.parse(response.body)
      end
    end

    def print_tweets(response)
      parse_tweets(response).map do |tweet|
        tweet.map { |k, v| "#{k}: #{v}"}
      end
    end

    def parse_tweets(response)
      JSON.parse(response.body)['statuses'].map do |status|
        {
          text: status['text'],
          tweet_url: "https://twitter.com/" + \
            "#{status['user']['screen_name']}" + \
            "/statuses/#{status['id']}"
        }
      end
    end

    def access_token
      @@token_preparer.prepare_access_token()
    end

    def url(twitter_user_name, count)
      "#{ BASE_URI }#{ path(twitter_user_name) }#{options(count)}"
    end

    def path(twitter_user_name)
      "/search/tweets.json?q=#{twitter_user_name}"
    end

    def options(count)
      "&count=#{count}"
    end

    def handle_timeouts
      begin
        yield
      rescue Net::OpenTimeout, Net::ReadTimeout
        {error: {message: 'Timeout error'}}
      end
    end
end
