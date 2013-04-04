# -*- coding: utf-8 -*-
#
require "uri"
require 'net/http'

class HudsonApi

  def self.get_job_list(hudson_url, auth_user, auth_password)
    url = "#{hudson_url}/xml?depth=0"
    HudsonApi.new.open url, auth_user, auth_password
  end

  def self.get_job_details(hudson_url, auth_user, auth_password)
    # job/build, view, primaryView は省く
    url = "#{hudson_url}/xml?depth=1" +
          "&xpath=/hudson" +
          "&exclude=/hudson/view" +
          "&exclude=/hudson/primaryView" +
          "&exclude=/hudson/job/build" +
          "&exclude=/hudson/job/lastCompletedBuild" +
          "&exclude=/hudson/job/lastStableBuild" +
          "&exclude=/hudson/job/lastSuccessfulBuild"
    HudsonApi.new.open url, auth_user, auth_password
  end

  def open(uri, auth_user, auth_password)

    begin
      http = create_http_connection(uri)
      request = create_http_request(uri, auth_user, auth_password)
    rescue => error
      raise HudsonApiException.new(error)
    end

    begin
      response = http.request(request)
    rescue Timeout::Error, StandardError => error
      raise HudsonApiException.new(error)
    end

    case response
    when Net::HTTPSuccess, Net::HTTPFound
      return response.body
    else
      raise HudsonApiException.new(response)
    end
  end

  def create_http_connection(uri)

    param = URI.parse( URI.escape(uri) )

    if "https" == param.scheme then
      param.port = 443 if param.port == nil || param.port == ""
    end

    retval = Net::HTTP.new(param.host, param.port)

    if "https" == param.scheme then
      retval.use_ssl = true
      retval.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    
    return retval

  end

  def create_http_request(uri, auth_user, auth_password)
    
    param = URI.parse( URI.escape(uri) )

    getpath = param.path
    getpath += "?" + param.query if param.query != nil && param.query.length > 0

    retval = Net::HTTP::Get.new(getpath)
    retval.basic_auth(auth_user, auth_password) if auth_user != nil && auth_user.length > 0

    return retval

  end
  
end
