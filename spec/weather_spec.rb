require 'spec_helper'

require 'ally/io/test'

require_relative '../lib/ally/render/weather'

describe Ally::Render::Weather do

  let(:io) { Ally::Io::Test.new }
  subject { Ally::Render::Weather }

  it 'say something back' do
    ans = io.pass('replace_me', subject)
    ans.should match(/some string expected as the return/i)
  end

end
