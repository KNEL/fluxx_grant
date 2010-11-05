module Rack
  class HgrantRack
    def initialize app
      @app = app
    end
    def call env
      if env["PATH_INFO"] =~ /^\/hgrantrss/
        @request_ids = ::Request.search_for_ids '', :with => {:grant => 1}, :limit => 1000, :order => 'id desc'
        @requests = ::Request.find_by_sql ["select requests.*, 
            program.name program_name,
            program_organization.name program_org_name, 
            program_organization.street_address program_org_street_address, program_organization.street_address2 program_org_street_address2, program_organization.city program_org_city,
            program_org_country_states.name program_org_state_name, program_org_countries.name program_org_country_name, program_organization.postal_code program_org_postal_code,
            program_org_countries.iso3 program_org_country_iso3,
            program_organization.url program_org_url
          FROM requests
          LEFT OUTER JOIN programs program ON program.id = requests.program_id
          LEFT OUTER JOIN organizations program_organization ON program_organization.id = requests.program_organization_id
          left outer join geo_states as program_org_country_states on program_org_country_states.id = program_organization.geo_state_id
          left outer join geo_countries as program_org_countries on program_org_countries.id = program_organization.geo_country_id
          WHERE requests.id in (?)
        ", @request_ids]
        [200, {"Content-Type" => "application/rss+xml"}, ::RenderHgrantsRssResponse.new(@requests)]
      else
        response, headers, content = @app.call env
        p "ESH: zzzzzz have response=#{response.inspect}, headers=#{headers.inspect}"
        [response, headers, content]
      end
    end
  end
end

class RenderHgrantsRssResponse
  
  def initialize rss_response
    @resp = rss_response
  end
  
  def each &block
    p "ESH: 222 in RenderHgrantsRssResponse each"
    render_requests_to_xml @resp, block
  end
  def render_requests_to_xml grants, block
    p "ESH: 333 in RenderHgrantsRssResponse render_requests_to_xml"
    block.call '<?xml version="1.0" encoding="UTF-8"?>\n'
    block.call '<rss version="2.0">\n'
    block.call "  <channel>\n"
    block.call "    <title>EnergyFoundation hGrant Feed</title>\n"
    block.call "    <description>EnergyFoundation hGrant Feed</description>\n"
    # TODO ESH: find a way to call paths from within rack middleware
    # block.call "    <link>#{hgrants_path}</link>\n"
    block.call "    <pubDate>#{Time.now}</pubDate>\n"
    block.call "    <language>en</language>\n"
    for model in grants
      render_request_to_xml model, block
    end
    block.call "  </channel>\n"
    block.call "</rss>\n"
  end

  def render_request_to_xml model, block
    block.call "<item>\n"
    block.call "  <title>#{model.program_org_name} #{model.granted ? model.grant_id : model.request_id} #{(model.amount_recommended || model.amount_requested).to_currency(:precision => 0)} </title>\n"
  
    block.call "<description>\n"
    block.call "  <![[CDATA\n"
    block.call "    <div class='hgrant'>\n"
    block.call "      <h2 class='title' name='grant-#{model.id}'>\n"
    # TODO ESH: find a way to call url_for or similar from within rack middleware
    # block.call "        <a class='url' href='#{url_for(model)}'>\n"
    block.call "          #{model.program_org_name} #{model.granted ? model.grant_id : model.request_id} #{(model.amount_recommended || model.amount_requested).to_currency(:precision => 0)}\n"
    block.call "        </a>\n"
    block.call "      </h2>\n"
    block.call "      <div>\n"
    block.call "        <span class='sector'>\n"
    block.call "          model.program_name\n"
    block.call "        </span>\n"
    block.call "      </div>\n"
    block.call "      <div class='grantor vcard'>\n"
    block.call "        <h3>Grantor</h3>\n"
    block.call "        <span class='fn org'>\n"
    block.call "          <a class='url' href='http://ef.org'>Energy Foundation</a></a>\n"
    block.call "        </span>\n"
    block.call "        <p class='adr'>\n"
    block.call "          <span class='street-address'>301 Battery Street</span>\n"
    block.call "          <span class='extended-address'>5th Floor</span>\n"
    block.call "          <span class='locality'>San Francisco</span>\n"
    block.call "          ,\n"
    block.call "          <abbr class='region' title='California'>CA</abbr>\n"
    block.call "          <span class='postal-code'>94111</span>\n"



    block.call "        </p>\n"
    block.call "      </div>\n"
    block.call "      <div class='geo-focus vcard'>\n"
    # TODO ESH: find a way to call url_for or similar from within rack middleware
    # block.call "        <a class='url' href='#{url_for(model)}'>permalink</a>\n"
    block.call "      </div>\n"
    block.call "      <div class='grantee vcard'>\n"
    block.call "        <h3>\n"
    block.call "          Grantee\n"
    block.call "          <span class='fn org'>\n"
    block.call "            #{model.program_org_name}\n"
    block.call "            <p class='adr'>\n"
    block.call "              <span class='street-address'>#{model.program_org_street_address}</span>\n"
    block.call "              <span class='extended-address'>#{model.program_org_street_address2}</span>\n"
    block.call "              <span class='locality'>#{model.program_org_city}</span>\n"
    block.call "              <span class='region' title='#{model.program_org_state_name}'>#{model.program_org_state_name}</span>\n"
    block.call "              <span class='country_name' title='#{model.program_org_country_name}'>#{model.program_org_country_iso3}</span>\n"
    block.call "              <span class='postal-code'>#{model.program_org_postal_code}</span>\n"
    block.call "            </p>\n"
    block.call "          </span>\n"
    block.call "        </h3>\n"
    block.call "      </div>\n"
    block.call "      <p class='amount'>\n"
    block.call "        <abbr class='currency' title='USD'>$</abbr>\n"
    # TODO ESH: Find a way to call number with precision from within rack middleware
    # block.call "        <abbr class='amount' title='#{model.amount_recommended}'>#{(model.amount_recommended ? model.amount_recommended.number_with_precision(:precision => 2, :separator => '.', :delimiter => ',') : '')}</abbr>\n"
    block.call "      </p>\n"
    block.call "      <p class='period'>\n"
    block.call "        Grant Period:\n"
    block.call "        <abbr class='dtstart' title='#{(model.grant_begins_at ? model.grant_begins_at.hgrant : '')}'>(model.grant_begins_at ? model.grant_begins_at.abbrev_month_year : '')</abbr>\n"
    block.call "        <abbr class='dtend' title='#{(model.grant_ends_at ? model.grant_ends_at.hgrant : '')}'>(model.grant_ends_at ? model.grant_ends_at.abbrev_month_year : '')</abbr>\n"
    block.call "      </p>\n"
    block.call "      <div class='description'>#{model.project_summary}</div>\n"
    block.call "     </div>\n"
    block.call "  ]]>\n"
    block.call "</description>\n"

    block.call "  <pubDate></pubDate>\n"
    block.call "  <link>/grant_requests/7</link>\n"
    block.call "  <guid>7</guid>\n"
    block.call "</item>\n"
  end  
end
