# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PhoneUtils do
  describe '.normalize' do
    it 'normalizes a 10-digit number to E.164' do
      expect(described_class.normalize('5558675309')).to eq('+15558675309')
    end

    it 'normalizes a formatted number' do
      expect(described_class.normalize('(555) 867-5309')).to eq('+15558675309')
    end

    it 'passes through an E.164 number unchanged' do
      expect(described_class.normalize('+15558675309')).to eq('+15558675309')
    end

    it 'returns nil for blank input' do
      expect(described_class.normalize('')).to be_nil
      expect(described_class.normalize(nil)).to be_nil
    end
  end
end
