require 'rails_helper'

RSpec.describe ChatwootHub do
  describe '.base_url' do
    it 'uses the static hub url outside development for enterprise edition' do
      with_modified_env CHATWOOT_HUB_URL: 'https://custom.example.com' do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))

        expect(described_class.base_url).to eq('https://hub.2.chatwoot.com')
      end
    end

    it 'uses CHATWOOT_HUB_URL in development for enterprise edition' do
      with_modified_env CHATWOOT_HUB_URL: 'https://custom.example.com' do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))

        expect(described_class.base_url).to eq('https://custom.example.com')
      end
    end
  end

  describe '.pricing_plan' do
    it 'treats self-hosted enterprise installations as enterprise locally' do
      allow(ChatwootApp).to receive(:enterprise?).and_return(true)
      allow(ChatwootApp).to receive(:self_hosted_enterprise?).and_return(true)

      expect(described_class.pricing_plan).to eq('enterprise')
    end

    it 'reads the persisted plan for cloud installations' do
      create(:installation_config, name: 'INSTALLATION_PRICING_PLAN', value: 'community')
      allow(ChatwootApp).to receive(:enterprise?).and_return(true)
      allow(ChatwootApp).to receive(:self_hosted_enterprise?).and_return(false)

      expect(described_class.pricing_plan).to eq('community')
    end
  end

  describe '.pricing_plan_quantity' do
    it 'uses max_limit for self-hosted enterprise installations' do
      allow(ChatwootApp).to receive(:enterprise?).and_return(true)
      allow(ChatwootApp).to receive(:self_hosted_enterprise?).and_return(true)
      allow(ChatwootApp).to receive(:max_limit).and_return(100_000)

      expect(described_class.pricing_plan_quantity).to eq(100_000)
    end
  end
end
