class AddTracksTestData < ActiveRecord::Migration
 def self.up
    Track.delete_all
    
    Track.create( :name => "The Creeps Orginal",
    :release_date => Date.new(2003),
    :label => Label.find( :first, :conditions => "name = 'Gigolo Records'"),
    :artist => Artist.find(:first, :conditions => "name = 'Freaks'") )
    
    Track.create( :name => "Rock you",
    :release_date => Date.new(2003),
    :label => Label.find( :first, :conditions => "name = 'Starschnitt'"),
    :artist => Artist.find(:first, :conditions => "name = 'Keen K'") )
    
    Track.create( :name => "Perspex Sex",
    :release_date => Date.new(2002),
    :label => Label.find( :first, :conditions => "name = 'Classic Rec.'"),
    :artist => Artist.find(:first, :conditions => "name = 'Ewan'") )
    
    Track.create( :name => "The Future is on Fire",
    :release_date => Date.new(2000),
    :label => Label.find( :first, :conditions => "name = 'Kanzleramt'"),
    :artist => Artist.create( :name => 'Christian Morgenstern',
                              :labels => [Label.find( :first, :conditions => "name = 'Kanzleramt'")]) )
    
    Track.create( :name => 'Bummelzug',
    :release_date => Date.new(2008),
    :label => Label.find( :first, :conditions => "name = '1 Takt'"),
    :artist => Artist.create( :name => 'Daso & Pawas',
                              :labels => [Label.find( :first, :conditions => "name = '1 Takt'")]) )
                              
    Track.create( :name => "Freaks Foo 1",
    :release_date => Date.new(2003),
    :label => Label.find( :first, :conditions => "name = 'Gigolo Records'"),
    :artist => Artist.find(:first, :conditions => "name = 'Freaks'") )
    
    Track.create( :name => "Freaks Foo 2",
    :release_date => Date.new(2003),
    :label => Label.find( :first, :conditions => "name = 'Gigolo Records'"),
    :artist => Artist.find(:first, :conditions => "name = 'Freaks'") )
    
    Track.create( :name => 'Numb',
    :release_date => Date.new(2008),
    :label => Label.find( :first, :conditions => "name = '1 Takt'"),
    :artist => Artist.find(:first, :conditions => "name = 'Daso & Pawas'") )
    
    Track.create( :name => "FOL 1",
    :release_date => Date.new(2003),
    :label => Label.find( :first, :conditions => "name = 'Other Label'"),
    :artist => Artist.find(:first, :conditions => "name = 'Freaks'") )
    
    Track.create( :name => "FOL 2",
    :release_date => Date.new(2003),
    :label => Label.find( :first, :conditions => "name = 'Other Label'"),
    :artist => Artist.find(:first, :conditions => "name = 'Freaks'") )
    
  end

  def self.down
    Track.delete_all
  end
end
