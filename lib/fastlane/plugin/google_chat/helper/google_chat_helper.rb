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
      # Handles both real newlines (\n, \r\n) and literal "\n" escape sequences
      # (backslash + n) that may appear in strings from shell/env sources.
      def self.paragraph(text)
        text.to_s
            .gsub("\r\n", "\n")
            .gsub('\\n', "\n")   # literal backslash-n -> real newline
            .gsub("\n", "<br>")
      end

      # Normalizes newlines to real "\n" for plain text messages
      # (literal backslash-n sequences become real newlines).
      def self.normalize_newlines(text)
        text.to_s.gsub("\r\n", "\n").gsub('\\n', "\n")
      end

      # Cleans a conventional-changelog markdown changelog for Google Chat:
      # - removes git hash/URL suffixes like "([1d54d0f](/1d54d0f...))"
      # - converts markdown headers (#, ##, ###, ...) to bold
      # - strips surrounding whitespace
      #
      # format:
      #   "card"  -> <b>headers</b> + "• " bullets (HTML, rendered by textParagraph)
      #   "plain" -> *headers* (markdown, rendered by {"text": ...})
      def self.clean_changelog(text, format: "card")
        cleaned = text.to_s
                    .gsub(/\s*\(\[[0-9a-fA-F]{6,}\]\([^)]*\)\)/, "")
                    .strip
        if format == "plain"
          cleaned.gsub(/^[#]{1,6}\s+(.+)$/, "*\\1*")
        else
          cleaned
            .gsub(/^[#]{1,6}\s+(.+)$/, "<b>\\1</b>")
            .gsub(/^-\s+/, "• ")   # "• " bullets (handle 1+ spaces after "-")
        end
      end

      # Builds a plain-text payload ({"text": ...}) that preserves newlines.
      def self.plain_payload(text)
        { text: normalize_newlines(text) }
      end

      # Builds a cardsV2 payload (Google Chat API v2) matching Google's
      # webhook card format: one section with textParagraph + buttonList,
      # description in the header subtitle, and a simple cardId.
      def self.card_payload(title:, description:, subtitle: nil, image_url: nil, section_title: nil,
                            section_description: nil, button_title: nil, button_url: nil)
        widgets = []
        header = {}
        header[:title] = title.to_s if title && !title.to_s.strip.empty?
        header[:imageUrl] = image_url if image_url && !image_url.to_s.strip.empty?

        has_section = !section_title.to_s.strip.empty? || !section_description.to_s.strip.empty?
        if has_section
          # description goes to the header subtitle (like the working curl)
          header[:subtitle] = (subtitle || description).to_s
          text_parts = []
          text_parts << "<b>#{section_title}:</b>" unless section_title.to_s.strip.empty?
          text_parts << section_description unless section_description.to_s.strip.empty?
          widgets << { textParagraph: { text: paragraph(text_parts.join("<br><br>")) } }
        else
          header[:subtitle] = subtitle.to_s if subtitle && !subtitle.to_s.strip.empty?
          if description && !description.to_s.strip.empty?
            widgets << { textParagraph: { text: paragraph(description) } }
          end
        end

        if button_title && button_url
          widgets << {
            buttonList: {
              buttons: [
                { text: button_title, onClick: { openLink: { url: button_url } } }
              ]
            }
          }
        end

        card = { sections: [{ widgets: widgets }] }
        card[:header] = header unless header.empty?

        { cardsV2: [{ cardId: "build-notification", card: card }] }
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