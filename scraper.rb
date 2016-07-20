require 'scraperwiki'
require 'mechanize'

def get_planning_links(page)
  list_of_applications = page.search("div.col_4")
  links_of_applications = list_of_applications.search('a')

  return links_of_applications
end

def return_only_application_links(links_on_main_div)
  links_to_planning_applications =[]

  links_on_main_div.each_with_index do |link, index|
    if index > 1
      links_to_planning_applications.push(link)
    end
  end

  return links_to_planning_applications
end

def save_one_application(planning_application_page, url)
  whole_page = planning_application_page.search("div.col_4").children
  #On Wednesday July 20, each page was a single element broken up with <br> tags, which is really annoying. For that reason, I've accessed the children elements directly.

  record = {
    "info_url" => url,
    "council_reference" => whole_page[4].inner_text.strip,
    "address" => whole_page[2].inner_text.strip,
    "on_notice_to" => whole_page[14].inner_text.strip,
    "description" => whole_page[9].inner_text.strip,
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

#This site has links to each planning application in one giant div. 
links_on_main_div = get_planning_links(first_page)
links_to_planning_applications = return_only_application_links(links_on_main_div)

links_to_planning_applications.each do |link|
  sleep(1)
  application_url = link.attributes['href']
  planning_application_page = agent.get(application_url)
  save_one_application(planning_application_page, url)
end