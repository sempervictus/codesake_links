require "net/http"
require "nokogiri"

module Codesake

  module Links
    module Api

      #    include Links::Google

      def self.get(url, proxy)
        return Links::Api.request({:url=>url, :proxy=>proxy, :method=>:get})
      end

      def self.head(url, proxy)
        return Links::Api.request({:url=>url, :proxy=>proxy, :method=>:head})
      end

      def self.code(url, proxy)
        res = Links::Api.get(url, proxy)
        (res.nil?)? -1 : res.code
      end

      def self.links(url, proxy)
        res = Links::Api.get(url, proxy)
        if res.nil?
          return []
        end
        doc = Nokogiri::HTML.parse(res.body)
        l = doc.css('a').map { |link| link['href'] }
        l
      end

      # TESTING: SPIDERS, ROBOTS, AND CRAWLERS (OWASP-IG-001)
      def self.robots(site)

        site = 'http://'+site unless site.start_with? 'http://' or site.start_with? 'https://'
        

        allow_list = []
        disallow_list = []

        begin
          res=Net::HTTP.get_response(URI(site+'/robots.txt'))
          return {:status=>:KO, :allow_list=>[], :disallow_list=>[], :error=>"robots.txt response code was #{res.code}"} if (res.code != "200")


          res.body.split("\n").each do |line|

            disallow_list << line.split(":")[1].strip.chomp if (line.downcase.start_with?('disallow'))
            allow_list << line.split(":")[1].strip.chomp if (line.downcase.start_with?('allow'))

          end
        rescue Exception => e
          return {:status=>:KO, :allow_list=>[], :disallow_list=>[], :error=>e.message}
        end

        {:status=>:OK, :allow_list=>allow_list, :disallow_list=>disallow_list, :error=>""}
      end

      def self.follow(url, proxy)
        l = Links::Api.links(url)
        l[0]
      end

      def self.human(code)
        case code.to_i
        when 200
          return "Open"
        when 301
          return "Moved"
        when 404
          return "Non existent"
        when 401
          return "Closed"
        when 403
          return "Forbidden"
        when -1
          return "No answer"
        else
          return "Broken"
        end
      end

      private

      def self.request(options)
        url    = options[:url]
        proxy  = options[:proxy]
        method = options[:method]

        begin
          uri = URI(url)
          if uri.scheme == 'http'
            unless proxy.nil?
              Net::HTTP::Proxy(proxy[:host], proxy[:port]).start(uri.host) {|http|
                if (method == :get)
                  res = http.get(uri.request_uri)
                else
                  res = http.head(uri.request_uri)
                end
                return res
              }
            else
              res = Net::HTTP.get_response(URI(url))
            end
            # res = Net::HTTP.get_response(URI(url))
          else
            request=Net::HTTP.new(uri.host, uri.port)
            request.use_ssl=true
            request.verify_mode = OpenSSL::SSL::VERIFY_NONE
            if (method == :get)
              res = request.get(uri.request_uri)
            else
              res = request.head(uri.request_uri)
            end

          end
          return res
        rescue
          return nil
        end

      end


    end
  end
end
