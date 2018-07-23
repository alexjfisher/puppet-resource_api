require 'spec_helper'
require 'tempfile'

RSpec.describe 'sensitive data' do
  let(:common_args) { '--verbose --trace --strict=error --modulepath spec/fixtures' }

  describe 'using `puppet apply`' do
    it 'is not exposed by notify' do
      stdout_str, _status = Open3.capture2e("puppet apply #{common_args} -e \"notice(Sensitive('foo'))\"")
      expect(stdout_str).not_to match %r{foo}
      expect(stdout_str).not_to match %r{warn|error}i
    end

    it 'is not exposed by a provider' do
      stdout_str, _status = Open3.capture2e("puppet apply #{common_args} --debug -e \"test_sensitive { bar: secret => Sensitive('foo') }\"")
      expect(stdout_str).not_to match %r{foo}
      expect(stdout_str).not_to match %r{warn|error}i
    end
  end
end
