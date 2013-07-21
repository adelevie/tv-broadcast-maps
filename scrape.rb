require "open-uri"
require "json"

require "bundler/setup"

require "rest_client"
require "pry"
require "pry-rescue"
require "pp"

require "parallel"

require 'fileutils'

def create_file(path, extension)
  dir = File.dirname(path)

  unless File.directory?(dir)
    FileUtils.mkdir_p(dir)
  end

  path << "#{extension}"
  File.new(path, 'w')
end

def facilities_url_from_state_abbreviation(state_abbreviation)
  "http://data.fcc.gov/mediabureau/v01/tv/facility/search/#{state_abbreviation}.json"
end

# facilities_from_state_abbreviation("CO")
def facilities_from_state_abbreviation(state_abbreviation)
  url             = facilities_url_from_state_abbreviation(state_abbreviation)
  raw_response    = open(url).read
  parsed_response = JSON.parse(raw_response)
  status          = parsed_response["status"]

  raise "Request Error: #{parsed_response}" if status != "OK"

  results       = parsed_response["results"]
  search_list   = results["searchList"]
  state_search  = search_list.select { |sl| sl["searchType"] == "State" }.first
  facilities    = state_search["facilityList"]

  facilities
end

def kml_string_from_facility_id(facility_id)
  url        = "https://data.fcc.gov/mediabureau/v01/tv/contour/facility/#{facility_id}.kml"
  kml_string = open(url).read

  kml_string
end

def geojson_from_kml_string(kml_string)
  url             = "http://ogre.adc4gis.com/convert"
  filename        = rand(10000000000).to_s + "temp.kml" 
  kml_file        = File.open(filename, 'w') {|f| f.write(kml_string) }

  raw_response    = RestClient.post(url, :params => {"upload" => File.read(filename)})

  request = RestClient::Request.new({
    :method  => :post,
    :url     => url,
    :payload => {
      :multipart => true,
      :upload    => File.new(filename, 'rb')
    }
  })      
  raw_response = request.execute

  File.delete(filename)

  parsed_response = JSON.parse(raw_response)
  error           = parsed_response["error"]

  raise "Request Error: #{parsed_response.inspect}" if error

  parsed_response
end

def geojson_from_facility_id(facility_id)
  begin
    kml_string = kml_string_from_facility_id(facility_id)
    geojson    = geojson_from_kml_string(kml_string)

    {"geojson" => geojson, "facility_id" => facility_id}
  rescue
    false
  end
end

states = JSON.parse(File.open("states.json").read)

def write_geojson_to_file(geojson, path)
  create_file(path, ".json")
  file = File.open(path, 'w') {|f| f.write(geojson) }

  file
end

Parallel.each(states) do |state|
  pp state

  state_abbreviation = state["abbreviation"]
  state_name         = state["name"]

  facilities   = facilities_from_state_abbreviation(state_abbreviation)
  facility_ids = facilities.map {|f| f["id"]}

  facility_ids.each do |facility_id|
    pp "#{state_name}-----#{facility_id}"
    geojson  = geojson_from_facility_id(facility_id)

    if geojson
      filename = geojson['facility_id'].to_s
      path     = "json/#{state_abbreviation}/#{filename}"
      resp = write_geojson_to_file(geojson["geojson"].to_json, path)
    end
  end

end
