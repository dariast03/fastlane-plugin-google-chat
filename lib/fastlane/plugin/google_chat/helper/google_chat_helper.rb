require 'fastlane_core/ui/ui'
require 'net/http'
require 'uri'
require 'json'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class GoogleChatHelper
      # Converts newlines to <br> so they render correctly inside a
      # textParagraph of a Google Chat card (API v2).
      def self.paragraph(text)
        text.to_s.gsub("\r\n", "\n").gsub("\n", "<br>")
      end

      # Builds a plain-text payload ({"text": ...}) that preserves newlines.
      def self.plain_payload(text)
        { text: text.to_s }
      end

      # Builds a cardsV2 payload (Google Chat API v2).
      # Keeps the original plugin contract: title, description,
      # section1Title, section1Description, buttonTitle, buttonUrl, imageUrl.
      def self.card_payload(title:, description:, image_url: nil, section1_title: nil,
                            section1_description: nil, button_title: nil, button_url: nil)
        widgets = []

        if description && !description.to_s.strip.empty?
          widgets << { textParagraph: { text: paragraph(description) } }
        end

        if section1_title || section1_description
          widgets << {
            keyValue: {
              topLabel: section1_title,
              content: paragraph(section1_description)
            }
          }
        end

        sections = []
        sections << { widgets: widgets } unless widgets.empty?

        if button_title && button_url
          sections << {
            widgets: [
              {
                buttons: [
                  {
                    textButton: {
                      text: button_title,
                      onClick: { openLink: { url: button_url } }
                    }
                  }
                ]
              }
            ]
          }
        end

        card = { sections: sections }
        card[:header] = { title: title.to_s } if title && !title.to_s.strip.empty?
        card[:header][:imageUrl] = image_url if image_url && !image_url.to_s.strip.empty?

        { cardsV2: [{ cardId: "google_chat_card", card: card }] }
      end

      # Sends the payload to the webhook. Returns true on success.
      def self.post(webhook, payload)
        uri = URI.parse(webhook)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == "https")
        request = Net::HTTP::Post.new(uri.request_uri)
        request["Content-Type"] = "application/json"
        request.body = JSON.generate(payload)

        response = http.request(request)

        unless response.is_a?(Net::HTTPSuccess)
          UI.error("Google Chat responded #{response.code}: #{response.body}")
          return false
        end

        true
      end
    end
  end
end