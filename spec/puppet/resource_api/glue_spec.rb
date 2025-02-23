require 'spec_helper'

# The tests in here are only a light dusting to avoid accidents,
# but for serious testing, these need to go through a full
# `puppet resource` read/write cycle to ensure that there is nothing
# funky happening with new puppet versions.
RSpec.describe 'the dirty bits' do
  describe Puppet::ResourceApi::ResourceShim do
    subject(:instance) do
      described_class.new({ namevarname: title, attr: 'value', attr_ro: 'fixed' }, 'typename', [:namevarname],
                          namevarname: { type: 'String', behaviour: :namevar, desc: 'the title' },
                          attr: { type: 'String', desc: 'a string parameter' },
                          attr_ro: { type: 'String', desc: 'a string readonly', behaviour: :read_only })
    end

    let(:title) { 'title' }

    describe '.values' do
      it { expect(instance.values).to eq(namevarname: 'title', attr: 'value', attr_ro: 'fixed') }
    end

    describe '.typename' do
      it { expect(instance.typename).to eq 'typename' }
    end

    describe '.title' do
      it { expect(instance.title).to eq 'title' }
    end

    describe '.prune_parameters(*_args)' do
      it { expect(instance.prune_parameters).to eq instance }
    end

    describe '.to_manifest' do
      it { expect(instance.to_manifest).to eq "typename { 'title': \n  attr => 'value',\n# attr_ro => 'fixed', # Read Only\n}" }
      context 'with nil values' do
        subject(:instance) do
          described_class.new({ namevarname: title, attr: nil, attr_ro: 'fixed' }, 'typename', [:namevarname],
                              namevarname: { type: 'String', behaviour: :namevar, desc: 'the title' },
                              attr: { type: 'String', desc: 'a string parameter' },
                              attr_ro: { type: 'String', desc: 'a string readonly', behaviour: :read_only })
        end

        it 'doesn\'t output them' do
          expect(instance.to_manifest).to eq "typename { 'title': \n# attr_ro => 'fixed', # Read Only\n}"
        end
      end
    end

    describe '.to_json' do
      it { expect(instance.to_json).to eq '{"title":{"attr":"value","attr_ro":"fixed"}}' }

      context 'with nil values' do
        subject(:instance) do
          described_class.new({ namevarname: title, attr: nil, attr_ro: 'fixed' }, 'typename', [:namevarname],
                              namevarname: { type: 'String', behaviour: :namevar, desc: 'the title' },
                              attr: { type: 'String', desc: 'a string parameter' },
                              attr_ro: { type: 'String', desc: 'a string readonly', behaviour: :read_only })
        end

        it 'doesn\'t output them' do
          expect(instance.to_json).to eq '{"title":{"attr_ro":"fixed"}}'
        end
      end
    end

    describe '.to_hierayaml' do
      it { expect(instance.to_hierayaml).to eq "  title:\n    attr: value\n    attr_ro: fixed\n" }

      context 'when the title contains YAML special characters' do
        let(:title) { "foo:\nbar" }

        it { expect(instance.to_hierayaml).to eq "  ? |-\n    foo:\n    bar\n  : attr: value\n    attr_ro: fixed\n" }
      end
    end
  end
end
