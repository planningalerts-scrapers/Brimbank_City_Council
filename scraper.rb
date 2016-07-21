require 'scraperwiki'
require 'mechanize'

def get_page_elements(page)
  elements_in_div = page.search("div.col_4")
  links_in_div = list_of_applications.search('a')

  return links_in_div
end

def return_only_application_links(links_on_main_div)
  links_to_planning_applications =[]

  links_on_main_div.each_with_index do |link, index|
    #The first two are links to documents, we don't need those
    if index > 1
      links_to_planning_applications.push(link)
    end
  end

  return links_to_planning_applications
end

def save_one_application(planning_application_page, url)
  elements_from_page = planning_application_page.search("div.col_4").children
  #On Wednesday July 20, each application was on a page in a single element broken up with <br> tags. For that reason, I've accessed the child elements directly.

  record = {
    "info_url" => url,
    "council_reference" => elements_from_page[4].inner_text.strip,
    "address" => elements_from_page[2].inner_text.strip,
    "on_notice_to" => elements_from_page[14].inner_text.strip,
    "description" => elements_from_page[9].inner_text.strip,
    "date_scraped" => Date.today.to_s
  }

  if (ScraperWiki.select("* from data where `council_reference`='#{record['council_reference']}'").empty? rescue true)
    ScraperWiki.save_sqlite(['council_reference'], record)
    puts record
  else
    puts "Skipping already saved record " + record['council_reference']
  end

end

url = "http://www.brimbank.vic.gov.au/DEVELOPMENT/Planning/Current_Advertised_Applications"
agent = Mechanize.new
first_page = agent.get(url)

#This site has links to each planning application in one giant div. Each application is on a separate page
links_on_main_div = get_planning_links(first_page)
links_to_planning_applications = return_only_application_links(links_on_main_div)

links_to_planning_applications.each do |link|
  sleep(1)
  application_url = link.attributes['href']
  planning_application_page = agent.get(application_url)
  save_one_application(planning_application_page, url)
end