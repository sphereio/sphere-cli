require 'spec_helper'

module Sphere
  describe CommandBase do
    describe '#parse_JSON' do
      it 'raise readable error' do
        expect { parse_JSON 'NonSense' }.to raise_error /^Can't parse JSON:/
      end
      it 'just works' do
        parse_JSON('{"foo":"bar"}')['foo'].should eq 'bar'
      end
    end
    describe '#pluralize' do
      it 'with number' do
        pluralize(1, 'line').should eq '1 line'
        pluralize(2, 'line').should eq '2 lines'
        pluralize(0, 'line').should eq '0 lines'

        pluralize(1, 'entry', 'entries').should eq '1 entry'
        pluralize(3, 'entry', 'entries').should eq '3 entries'
      end
      it 'without number' do
        pluralize(1, 'is', 'are', true).should eq 'is'
        pluralize(7, 'I', 'we',  true).should eq 'we'
      end
    end
    describe '#get_file_input' do
      it 'file not given' do
        expect { get_file_input [] }.to raise_error "No filename provided."
      end
      it 'file does not exists' do
        expect { get_file_input 'absent_file.txt' }.to raise_error "File 'absent_file.txt' does not exist."
      end
    end
    describe '#jsonValue' do
      it 'simple attribute' do
        j = '{"name":"foo"}'
        jsonValue(parse_JSON(j), %w'name').should eq 'foo'
      end
      it 'nested attribute' do
        j = '{"price":{"amount":1000}}'
        jsonValue(parse_JSON(j), %w'price amount').should eq "1000"
      end
      it 'attribute within array' do
        j = '{"attributes":[{"name":"foo","value":1},{"n":"bar","v":2}]}'
        jsonValue(parse_JSON(j), %w'attributes [name=foo/value]').should eq "1"
        jsonValue(parse_JSON(j), %w'attributes [n=bar/v]').should eq "2"
      end
    end
  end
end
