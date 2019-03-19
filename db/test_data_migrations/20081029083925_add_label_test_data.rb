class AddLabelTestData < ActiveRecord::Migration
  def self.up
    Label.delete_all
    
    Label.create( :name => "Gigolo Records",
    :www => "www.gigolo-records.de")
    
    Label.create( :name => "Starschnitt",
    :www => "www.starschnitt.com")
    
    Label.create( :name => "Classic Rec." )
    
    Label.create( :name => "Kanzleramt",
    :www => "www.kanzleramt.com" )
    
    Label.create( :name => "Compost Records",
    :www => "www.compost-records.de" )
    
    Label.create( :name => "1 Takt",
    :www => 'www.fake.com')
    
    Label.create( :name => "Other Label")
  end

  def self.down
    Label.delete_all
  end
end
