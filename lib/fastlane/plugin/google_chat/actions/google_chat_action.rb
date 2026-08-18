require 'fastlane/action'
require_relative '../helper/google_chat_helper'
require 'net/http'
require 'uri'
require 'json'

module Fastlane
  module Actions
    class GoogleChatAction < Action
      def self.run(params)
        webhook = params[:webhook]

        if params[:message_type].to_s == "plain"
          # Plain text message: preserves newlines as-is.
          payload = Helper::GoogleChatHelper.plain_payload(params[:description])
        else
          # Card v2: description with <br>, title, section and button(s).
          payload = Helper::GoogleChatHelper.card_payload(
            title: params[:title],
            description: params[:description],
            subtitle: params[:subtitle],
            image_url: params[:imageUrl],
            section_title: params[:section1Title],
            section_description: params[:section1Description],
            button_title: params[:buttonTitle],
            button_url: params[:buttonUrl],
            buttons: params[:buttons]
          )
        end

        if Helper::GoogleChatHelper.post(webhook, payload)
          UI.message("Message sent!")
        else
          UI.user_error!("Failed to send message to Google Chat")
        end
      end

      def self.description
        "Send messages to Google Chat"
      end

      def self.authors
        ["Narlei Américo Moreira"]
      end

      def self.return_value
        nil
      end

      def self.details
        "Send messages to Google Chat rooms. Uses the Google Chat API v2 (cardsV2) and supports both card and plain-text messages."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :webhook,
                                       env_name: "GOOGLE_CHAT_WEBHOOK",
                                       description: "The Google Chat webhook URL",
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :title,
                                       env_name: "GOOGLE_CHAT_TITLE",
                                       description: "Title of the card",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :description,
                                       env_name: "GOOGLE_CHAT_DESCRIPTION",
                                       description: "Description / body of the message",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :subtitle,
                                       env_name: "GOOGLE_CHAT_SUBTITLE",
                                       description: "Subtitle of the card header",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :imageUrl,
                                       env_name: "GOOGLE_CHAT_IMAGE_URL",
                                       description: "Image URL for the card header",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :section1Title,
                                       env_name: "GOOGLE_CHAT_SECTION1_TITLE",
                                       description: "Top label of the key-value widget",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :section1Description,
                                       env_name: "GOOGLE_CHAT_SECTION1_DESCRIPTION",
                                       description: "Content of the key-value widget",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :buttonTitle,
                                       env_name: "GOOGLE_CHAT_BUTTON_TITLE",
                                       description: "Text of the button",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :buttonUrl,
                                       env_name: "GOOGLE_CHAT_BUTTON_URL",
                                       description: "URL opened by the button",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :buttons,
                                       env_name: "GOOGLE_CHAT_BUTTONS",
                                       description: "Array of buttons: [{ text: 'Label', url: 'https://...' }]",
                                       optional: true,
                                       type: Array,
                                       skip_type_validation: true),
          FastlaneCore::ConfigItem.new(key: :message_type,
                                       env_name: "GOOGLE_CHAT_MESSAGE_TYPE",
                                       description: "How to send the message: 'card' (default, uses cardsV2) or 'plain' (simple text that keeps newlines)",
                                       optional: true,
                                       type: String,
                                       default_value: "card")
        ]
      end

      def self.is_supported?(platform)
        [:ios, :mac, :android].include?(platform)
      end
    end
  end
end