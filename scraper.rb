require 'scraperwiki'
require 'mechanize'

url = "https://www.brimbank.vic.gov.au/advertised-plans/current-advertised-plans"
agent = Mechanize.new

page_no = 0

loop do
  page = agent.get("#{url}?page=#{page_no}")
  
  tbody = page.at("table tbody")
  # If we're past the last page there is no table of results
  break if tbody.nil?

  tbody.search("tr").each do |tr|
    record = {
      "council_reference" => tr.at("td.views-field-title").inner_text.strip,
      "address" => tr.at("td.views-field-field-address").inner_text.strip + ", VIC",
      "description" => tr.at("td.views-field-body").inner_text.strip,
      "info_url" => tr.at("td.views-field-field-document-and-plans a")["href"],
      "date_scraped" => Date.today.to_s
    }
    puts "Saving record #{record['council_reference']} - #{record['address']}" 
    ScraperWiki.save_sqlite(['council_reference'], record)
  end
  page_no += 1
end
