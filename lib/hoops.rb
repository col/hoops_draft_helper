require 'HTTParty'
require 'Nokogiri'
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

USERNAME = '<username>'
UID = '<user_id>'
SESSION_ID = '<session id>'
LEAGUE_ID = '<league id>'

class Hoops

  attr_accessor :player_pages

  def initialize
    doc = HTTParty.get(
      "https://basketball.sports.ws/ajax/player_stats.x?y=17_18&filterfteam_off=1&noend=1&league=#{LEAGUE_ID}",
      headers: {
        'Accept' => 'text/html',
        'X-Requested-With' => 'XMLHttpRequest',
        'Cookie' => cookie
      }
    )
    @parsed_page = Nokogiri::HTML(doc)
    links = @parsed_page.xpath('//td//a').map { |link| link.attributes['href'].value }.select { |href| href.start_with?('/fantasy/') }
    links = links.uniq

    adps = links.map { |link|
      stats = stats(link)
      puts "#{link} \t\t\t\t\t #{stats[:adp]} \t\t\t\t\t #{stats[:owned]}"
      [link, stats]
    }
    @player_pages = Hash[adps]
  end

  def stats(relative_path)
    page = load_page(relative_path)
    content = page.css('div.center.normal-font.padding').map { |e| e.content }
    adp = content.select { |c| !c.nil? && c.end_with?('ADP') }.first
    adp = (adp || '').gsub('ADP', '')
    owned = content.select { |c| !c.nil? && c.end_with?('Own%') }.first
    owned = (owned || '').gsub('Own%', '')
    {adp: adp, owned: owned}
  end

  def load_page(relative_path)
    doc = HTTParty.get(
      "https://basketball.sports.ws#{relative_path}",
      headers: {
        'Accept' => 'text/html',
        'Cookie' => cookie
      }
    )
    Nokogiri::HTML(doc)
  end

  def cookie
    "PHPSESSID=#{SESSION_ID}; uid=#{UID}; username=#{USERNAME};"
  end
end
