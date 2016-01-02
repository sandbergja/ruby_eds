require 'nokogiri'
require 'json'
require 'httpclient'

module RubyEDS

  def authenticate_user(username, password)
    auth_json = {"UserId"=>"#{username}","Password"=>"#{password}","InterfaceId"=>"WSapi"}.to_json
    response = HTTPClient.post('https://eds-api.ebscohost.com/authservice/rest/uidauth', 
      auth_json, 'Content-Type' => 'application/json')
    doc = Nokogiri::XML(response.body)
    doc.remove_namespaces!
    @auth_token = doc.xpath("//AuthToken").inner_text
  end

  def open_session(profile, guest, auth_token)
    response = HTTPClient.get('http://eds-api.ebscohost.com/edsapi/rest/CreateSession', 
      {"profile"=>"#{profile}", "guest"=>"#{guest}"}, 
      {'ContentType'=>'application/json', "x-authenticationToken" => "#{auth_token}" } )
    doc = Nokogiri::XML(response.body)
    doc.remove_namespaces!
    session_token = doc.xpath("//SessionToken").inner_text
  end

  def close_session(session_token, auth_token)
    response = HTTPClient.get("http://eds-api.ebscohost.com/edsapi/rest/endsession", 
      { "sessiontoken"=> "#{session_token}" }, 
      {"ContentType" => 'application/json', 
        "x-authenticationToken"=>"#{auth_token}", 
        "x-sessionToken"=>"#{session_token}"})
    doc = Nokogiri::XML(response.body)
    doc.remove_namespaces!
    success = doc.xpath("//IsSuccessful").inner_text
  end
  
  def get_info(session_token, auth_token, return_type="xml")
    response = HTTPClient.get("http://eds-api.ebscohost.com/edsapi/rest/info", {}, 
      { "x-authenticationToken" => "#{auth_token}", 
      "x-sessionToken" => "#{session_token}", 
      'Accept' => "#{return_type}"})
  end

  def basic_search(query, session_token, auth_token, view='brief', offset=1, limit=10, order='relevance', return_type="xml")
    response = HTTPClient.get("http://eds-api.ebscohost.com/edsapi/rest/Search", 
      { "query-1" => "#{query}" }, 
      {"x-authenticationToken" => "#{auth_token}", 
      "x-sessionToken" => "#{session_token}", 
      "Accept" => "#{return_type}"})
  end


  def search(query_strings, session_token, auth_token, return_type = 'xml', opts = {})
    query_hash = opts

    unless query_strings.respond_to?(:each)
      query_strings = [query_strings.to_s]
    end

    i = 1
    query_strings.each do |query_string|
      query_num = 'query-' + i.to_s
      query_hash[query_num] = query_string
      i = i+1
    end
    
    header_hash = {"x-authenticationToken" => "#{auth_token}", 
      "x-sessionToken" => "#{session_token}",
      'Accept' => return_type}
    
    response = HTTPClient.get("http://eds-api.ebscohost.com/edsapi/rest/Search", 
      query_hash, 
      header_hash)
  end

  def retrieve(dbid, an, session_token, auth_token, return_type = 'xml')
    response = HTTPClient.get("http://eds-api.ebscohost.com/edsapi/rest/Retrieve", 
      { "dbid" => "#{dbid}",
      "an" => "#{an}"}, 
      {"x-authenticationToken" => "#{auth_token}", 
      "x-sessionToken" => "#{session_token}", 
      "Accept" => "#{return_type}"})
  end

  def advanced_search(search_json, return_type="xml")
  end
 
end
