require 'spec_helper'

module Sphere
  describe CommandBase do
    describe '#get_val' do
      it 'with all languages' do
        set_language({ :lang => 'en' })
        set_language_attributes ['name']
        v = get_val(
          ['Deutsch', 'English'],
          'name',
          { 'name.de' => 0, 'name.en' => 1 },
        )
        v.size.should eq 2
        v['de'].should eq 'Deutsch'
        v['en'].should eq 'English'
      end
      it 'fall back language' do
        set_language({ :lang => 'en' })
        set_language_attributes ['name']
        v = get_val(
          ['Content'],
          'name',
          { 'name' => 0 }
        )
        v.size.should eq 1
        v['en'].should eq 'Content'
      end
      it 'non language attribute' do
        set_language({ :lang => 'en' })
        set_language_attributes ['name']
        v = get_val(
          ['77'],
          'size',
          { 'size' => 0 }
        )
        v.should eq '77'
        v.class.should be String
      end
      it 'get value from parsed CSV' do
        row = CSV.parse 'EUR 100'
        row.class.should be Array
        row[0].class.should be Array
        v = get_val(
          row[0],
          'prices',
          { 'prices' => 0 }
        )
        v.should eq 'EUR 100'
        v.class.should be String
      end
    end
  end
end
