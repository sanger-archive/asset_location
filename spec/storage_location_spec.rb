require 'spec_helper'

describe StoredEntity do
  describe '.storage_location' do
    it 'generates a safe query' do
      connection = mock('ActiveRecord connection')
      connection.should_receive(:select_one).with(/SAFELY QUOTED BARCODE PREFIX.+SAFELY QUOTED ASSET BARCODE/m).and_return('location')
      connection.stub(:quote_table_name).with('STORED_ENTITY').and_return('STORED_ENTITY')
      connection.stub(:quote).with("';DROP TABLE bad_person_here;--").and_return('SAFELY QUOTED BARCODE PREFIX')
      connection.stub(:quote).with(99).and_return('SAFELY QUOTED ASSET BARCODE')
      StoredEntity.stub(:connection).and_return(connection)

      StoredEntity.storage_location(99, "';DROP TABLE bad_person_here;--").should == 'location'
    end
  end
end
