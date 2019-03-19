class AddArtistTestData < ActiveRecord::Migration
  def self.up
    Artist.delete_all
    
    Artist.create( :name => "Freaks",
    :labels => [Label.find(:first, :conditions => "name = 'Gigolo Records'")] )
    
    Artist.create( :name => "Keen K",
    :www => "www.keenk.de",
    :labels => [Label.find(:first, :conditions => "name = 'Starschnitt'")])
    
    Artist.create( :name => "Ewan",
    :labels => [Label.find(:first, :conditions => "name = 'Classic Rec.'")],
    :www => 'www.not-true.com')
    
    Artist.create ( :name => "Ural 13 Dictators",
    :labels => [Label.create(:name => "Alphabet City",
                             :www => "www.alphabetcity.de")] )
                             
    Artist.create( :name => "Shari Vari",
    :labels => [Label.find(:first, :conditions => "name = 'Gigolo Records'")] )
    
    Artist.create( :name => "Miss Kittin",
    :labels => [Label.find(:first, :conditions => "name = 'Gigolo Records'")] )
    
    Artist.create( :name => "The Hacker",
    :labels => [Label.find(:first, :conditions => "name = 'Gigolo Records'")],
    :www => 'www.porno.de')
    
    Artist.create( :name => "DJ Hell",
    :labels => [Label.find(:first, :conditions => "name = 'Gigolo Records'"),
                Label.create(:name => "EFA",
                             :www => "www.efa.de"),
                Label.create(:name => "Virgin",
                             :www => "www.virgin.de")] )
    
  end

  def self.down
    Artist.delete_all
  end
end
