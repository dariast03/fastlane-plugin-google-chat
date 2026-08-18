describe Fastlane::Helper::GoogleChatHelper do
  describe '#paragraph' do
    it 'replaces newlines with <br>' do
      expect(Fastlane::Helper::GoogleChatHelper.paragraph("line1\nline2")).to eq("line1<br>line2")
    end

    it 'handles CRLF' do
      expect(Fastlane::Helper::GoogleChatHelper.paragraph("a\r\nb")).to eq("a<br>b")
    end

    it 'handles nil' do
      expect(Fastlane::Helper::GoogleChatHelper.paragraph(nil)).to eq("")
    end
  end

  describe '#plain_payload' do
    it 'returns a text payload' do
      expect(Fastlane::Helper::GoogleChatHelper.plain_payload("hello\nworld"))
        .to eq({ text: "hello\nworld" })
    end
  end

  describe '#card_payload' do
    it 'builds a cardsV2 payload' do
      payload = Fastlane::Helper::GoogleChatHelper.card_payload(
        title: "Title",
        description: "line1\nline2",
        section1_title: "Changes",
        section1_description: "feat: x\nfix: y",
        button_title: "View",
        button_url: "https://example.com"
      )

      expect(payload[:cardsV2]).to be_an(Array)
      card = payload[:cardsV2].first[:card]
      expect(card[:header][:title]).to eq("Title")
      expect(card[:sections].first[:widgets].first[:textParagraph][:text]).to eq("line1<br>line2")
      decorated = card[:sections].first[:widgets][1][:decoratedText]
      expect(decorated[:topLabel]).to eq("Changes")
      expect(decorated[:text]).to eq("feat: x<br>fix: y")
      expect(card[:sections].last[:widgets].first[:buttonList][:buttons].first[:text]).to eq("View")
    end
  end
end