require 'spec_helper' 
include GLI::Extensions
require 'gli'
include GLI

module GLI
  describe Extensions do
    describe '#set_all' do
      it 'ignore default values' do
        c = {}
        set_all ['x'], c, nil
        c.size.should be 0
      end
      it 'symbol 2 string' do
        c = {}
        set_all ['foo', 'bar'], c, 'val'
        c.size.should be 4
        c['foo'].should eq 'val'
        c[:foo].should eq 'val'
        c['bar'].should eq 'val'
        c[:bar].should eq 'val'
      end
      context 'with switches and flags' do
        before do
          @switches = { 
            :f => Switch.new(['f', 'foo'], { :default_value => 'bar' }),
            :noaliases => Switch.new(['noaliases'], { :default_value => 'some' }),
            :n => Switch.new(['n', 'nodefault']),
          }
          @flags = {
            :b => Flag.new(['b', 'bar'], { :default_value => 'foo' }),
            :no_aliases => Flag.new(['noaliases'], { :default_value => 'stuff' }),
            :d => Flag.new(['d', 'default_nada'], {}),
          }
        end
        describe '#name2default' do
          it 'just works' do
            n2d = name2default @switches, @flags
            n2d.size.should be 10
            puts n2d
            n2d[:f].should eq 'bar'
            n2d[:foo].should eq 'bar'
            n2d[:noaliases].should eq 'some'
            n2d[:n].should eq false
            n2d[:nodefault].should eq false
            n2d[:b].should eq 'foo'
            n2d[:bar].should eq 'foo'
            n2d[:no_aliases].should eq 'stuff'
            n2d[:d].should eq nil
            n2d[:default_nada].should eq nil
          end
        end
        describe '#apply_to_aliases' do
          it 'just works' do
            c = { 'bar' => 'myval' }
            n = apply_to_aliases c, switches, flags
            n.size.should be 4
            n[:b].should eq 'myval'
            n[:bar].should eq 'myval'
            n['b'].should eq 'myval'
            n['bar'].should eq 'myval'
          end
        end
      end
      describe '#load_config_file' do
        it 'no config files' do
          load_config_files({})
        end
        it 'no existing files are ignored' do
          load_config_files({ :config => 'some-file-that-never-exists.yaml' })
        end
      end
    end
  end
end
