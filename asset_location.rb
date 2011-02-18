require 'rubygems'
require 'bundler'
require "rexml/document"
Bundler.setup
require 'sinatra'
require 'active_record'

APP_ROOT = File.dirname(File.expand_path(__FILE__))
RAILS_ENV = (ENV['RAILS_ENV'] ||= 'development')
@@database = YAML::load(File.open( File.join(APP_ROOT,'config/database.yml') ))

helpers do
  def get_version_string
    require File.join(APP_ROOT,'lib/versionstrings')
    Deployed::VERSION_STRING
  end
end

class StoredEntity < ActiveRecord::Base

  set_table_name "STORED_ENTITY"

  def self.storage_location(asset_barcode,barcode_prefix="DN")
    storage_location = self.connection.select_one <<-EOS
    select
    sa.name as STORAGE_AREA,
    sd.name as STORAGE_DEVICE,
    ba.name as BUILDING_AREA,
    b.description as BUILDING
    from
    stored_entity se,
    entity_movement em,
    storage_area_location sal,
    storage_area sa,
    device_location dl,
    storage_device sd,
    building_area ba,
    building b
    where se.prefix = '#{barcode_prefix}'
    and se.id_storedobject = #{asset_barcode.to_i}
    and se.id_storage = em.id_storage
    and em.is_current = 1
    and em.id_sarealocation = sal.id_sarealocation
    and sal.is_current = 1
    and sal.id_area = sa.id_area
    and sal.id_device_location = dl.id_device_location
    and dl.is_current = 1
    and dl.id_storage_device = sd.id_storage_device
    and dl.id_buildingarea = ba.id_buildingarea
    and ba.id_building = b.id_building
    EOS
  end
end

get '/locations/asset.xml' do
  StoredEntity.establish_connection(
    @@database["#{RAILS_ENV}_cas"]
  )
  location = StoredEntity.storage_location(params[:barcode], params[:barcode_prefix])
  
  content_type 'application/xml', :charset => 'utf-8'
  <<-_EOF_
<?xml version="1.0" encoding="UTF-8"?><location>
  <building_area>#{location['building_area']}</building_area>
  <storage_area>#{location['storage_area']}</storage_area>
  <storage_device>#{location['storage_device']}</storage_device>
  <building>#{location['building']}</building>
</location>
_EOF_
end

get '/locations/asset.json' do
  StoredEntity.establish_connection(
    @@database["#{RAILS_ENV}_cas"]
  )
  location = StoredEntity.storage_location(params[:barcode], params[:barcode_prefix])
  
  content_type 'application/json', :charset => 'utf-8'
  <<-_EOF_
{
"location":
{

  "building_area": "#{location['building_area']}",
  "storage_area": "#{location['storage_area']}",
  "storage_device": "#{location['storage_device']}",
  "building": "#{location['building']}"
 }
}
_EOF_
end


get '/' do
  content_type 'text/plain', :charset => 'utf-8'
  get_version_string
end
