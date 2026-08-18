describe Fastlane::Helper::GoogleChatHelper do
  describe '#paragraph' do
    it 'replaces newlines with <br>' do
      expect(Fastlane::Helper::GoogleChatHelper.paragraph("line1\nline2")).to eq("line1<br>line2")
    end

    it 'handles literal backslash-n escape sequences' do
      expect(Fastlane::Helper::GoogleChatHelper.paragraph("line1\\nline2")).to eq("line1<br>line2")
    end

    it 'handles CRLF' do
      expect(Fastlane::Helper::GoogleChatHelper.paragraph("a\r\nb")).to eq("a<br>b")
    end

    it 'handles nil' do
      expect(Fastlane::Helper::GoogleChatHelper.paragraph(nil)).to eq("")
    end
  end

  describe '#clean_changelog' do
    it 'removes git hash/URL suffixes' do
      out = Fastlane::Helper::GoogleChatHelper.clean_changelog(
        "- fix stuff ([4e92c34](/4e92c34fb27d44bc75b088d3ba5bd81f002a1c2c))"
      )
      expect(out).to eq("• fix stuff")
    end

    it 'converts markdown headers to <b>bold</b> and bullets to • (card format)' do
      out = Fastlane::Helper::GoogleChatHelper.clean_changelog(
        "# 2.1.0 (2026-08-18)\n\n### Features\n- add shorebird\n- add firebase"
      )
      expect(out).to include("<b>2.1.0 (2026-08-18)</b>")
      expect(out).to include("<b>Features</b>")
      expect(out).to include("• add shorebird")
    end

    it 'converts bullet dashes with extra spaces (double-space commit subjects)' do
      out = Fastlane::Helper::GoogleChatHelper.clean_changelog(
        "-  add firebase_remote_config and dynamic_app_icon_flutter_plus packages"
      )
      expect(out).to eq("• add firebase_remote_config and dynamic_app_icon_flutter_plus packages")
    end

    it 'converts headers to *bold* (plain format)' do
      out = Fastlane::Helper::GoogleChatHelper.clean_changelog(
        "# 2.1.0 (2026-08-18)\n\n### Features\n- add shorebird",
        format: "plain"
      )
      expect(out).to include("*2.1.0 (2026-08-18)*")
      expect(out).to include("*Features*")
      expect(out).to include("- add shorebird")
    end
  end

  describe '#plain_payload' do
    it 'returns a text payload' do
      expect(Fastlane::Helper::GoogleChatHelper.plain_payload("hello\nworld"))
        .to eq({ text: "hello\nworld" })
    end

    it 'normalizes literal backslash-n to real newlines' do
      expect(Fastlane::Helper::GoogleChatHelper.plain_payload("hello\\nworld"))
        .to eq({ text: "hello\nworld" })
    end
  end

  describe '#card_payload' do
    it 'builds a cardsV2 payload matching the webhook card format' do
      payload = Fastlane::Helper::GoogleChatHelper.card_payload(
        title: "Nueva build (staging)",
        description: "iOS 2.0.0+201 (staging)",
        section_title: "Cambios incluidos",
        section_description: "<b>Features</b><br>• add shorebird\n• add firebase",
        button_title: "Ver",
        button_url: "https://example.com"
      )

      expect(payload[:cardsV2]).to be_an(Array)
      card = payload[:cardsV2].first[:card]
      expect(card[:header][:title]).to eq("Nueva build (staging)")
      expect(card[:header][:subtitle]).to eq("iOS 2.0.0+201 (staging)")
      # single section
      expect(card[:sections].length).to eq(1)
      widgets = card[:sections].first[:widgets]
      # textParagraph includes the bold section title + content with <br>
      text = widgets.first[:textParagraph][:text]
      expect(text).to include("<b>Cambios incluidos:</b><br><br><b>Features</b><br>• add shorebird<br>• add firebase")
      # buttonList in the same section
      button = widgets.last[:buttonList][:buttons].first
      expect(button[:text]).to eq("Ver")
      expect(button[:onClick][:openLink][:url]).to eq("https://example.com")
    end

    it 'builds multiple buttons from the buttons array' do
      payload = Fastlane::Helper::GoogleChatHelper.card_payload(
        title: "T",
        description: "D",
        buttons: [
          { text: "Abrir Consola", url: "https://console.example.com" },
          { text: "Descargar APK (1 hora)", url: "https://download.example.com" }
        ]
      )
      widgets = payload[:cardsV2].first[:card][:sections].first[:widgets]
      list = widgets.last[:buttonList][:buttons]
      expect(list.length).to eq(2)
      expect(list[0][:text]).to eq("Abrir Consola")
      expect(list[1][:text]).to eq("Descargar APK (1 hora)")
      expect(list[1][:onClick][:openLink][:url]).to eq("https://download.example.com")
    end
  end
end