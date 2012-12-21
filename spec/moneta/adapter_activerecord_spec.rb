# Generated by generate.rb
require 'helper'

describe_moneta "adapter_activerecord" do
  def new_store
    Moneta::Adapters::ActiveRecord.new(:connection => { :adapter => (defined?(JRUBY_VERSION) ? 'jdbcsqlite3' : 'sqlite3'), :database => File.join(make_tempdir, 'adapter_activerecord') })
  end

  def load_value(value)
    Marshal.load(value)
  end

  include_context 'setup_store'
  it_should_behave_like 'null_stringkey_stringvalue'
  it_should_behave_like 'store_stringkey_stringvalue'
  it_should_behave_like 'returndifferent_stringkey_stringvalue'
  it 'updates an existing key/value' do
    store['foo/bar'] = '1'
    store['foo/bar'] = '2'
    records = store.table.find :all, :conditions => { :k => 'foo/bar' }
    records.count.should == 1
  end

  it 'uses an existing connection' do
    ActiveRecord::Base.establish_connection :adapter => (defined?(JRUBY_VERSION) ? 'jdbcsqlite3' : 'sqlite3'), :database => File.join(make_tempdir, 'activerecord-existing')

    store = Moneta::Adapters::ActiveRecord.new
    store.table.should be_table_exists
  end

end
