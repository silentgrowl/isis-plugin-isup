require "nokogiri"

module Isis
  module Plugin
    class IsUp < Isis::Plugin::Base
      DOMAIN_REGEX = /^[a-z0-9]+([\-]{1}[a-z0-9]+)*\.[a-z]{2,5}$/ix
      SLACK_REGEX = /^<http:\/\/(?<url>[a-zA-Z\/\.:]+\w)\|/

      def respond_to_msg?(msg, speaker)
        @commands = msg.downcase.split
        @commands[0] == '!isup'
      end

      private

      def response_html
        response = scrape(@commands[1])
        return %Q(Sorry, I can't process that name) unless response
        if response =~ /It's just you/
          "#{@commands[1]} appears to be up. All good."
        else
          "#{@commands[1]} appears to be <b>down</b>! Panic!"
        end
      end

      def response_md
        cleaned_domain = SLACK_REGEX.match(@commands[1])[:url] # Slack auto-linkifies domains, rewrite cleaned domain
        response = scrape(cleaned_domain)
        return %Q(Sorry, I can't process that name) unless response
        if response =~ /It's just you/
          "#{cleaned_domain} appears to be up. All good."
        else
          "#{cleaned_domain} appears to be *down*! Panic!"
        end
      end

      def response_text
        response = scrape(@commands[1])
        return %Q(Sorry, I can't process that name) unless response
        if response =~ /It's just you/
          "#{@commands[1]} appears to be up. All good."
        else
          "#{@commands[1]} appears to be down! Panic!"
        end
      end

      def scrape(domain)
        domain = domain.split('www.')[1] if /www\./.match(domain)
        if DOMAIN_REGEX.match(domain)
          page = Nokogiri.HTML(open("http://isup.me/#{domain}"))
          page.css('#container').text
        else
          false
        end
      end
    end
  end
end
