require 'watir'
require 'open-uri'
require 'nokogiri'
require 'sanitize'

oops = 'oops, you seem to be missing arguments'

#with_date d w m y

#returns an array of links to investigate
def get_links(location, pages_to_crawl)
  list_of_links =[]
  b = Watir::Browser.new :chrome
  b.goto(location)
  for x in 0...pages_to_crawl
    for y in 1..10
      
      link = b.link id: 'title_'+(x*10+y).to_s
      puts link.href
      
    end
    nxt = b.link href: 'javascript:document.nextform.submit();'
    nxt.exists?
    nxt.click
  end
  
end

#creates appropriate GET request
def build_search_url(search,date)
  url = 'https://www.startpage.com/do/search?query='+search+'&with_date='+date
  return url
end




def down_html_from_links_open_uri(links, dir_name)

  Dir.mkdir dir_name unless Dir.exist?(dir_name)

  for i in 0...links.length
    link = links[i].first
    begin
    html_file = "<!--"+link+"-->\n" + open(link).read
    File.write(dir_name+'/'+i.to_s+'.html', html_file)
    puts 'downloaded index'+i.to_s
    rescue
      puts "skipping index "+link+" .. encountered issue with download :("
    end
    
  end
  
end

def occurrence_counter(string, substring)
  return string.scan(/(?=#{substring})/).count
end



# create steralized text including title meta data and body text that will be searched for given keyworks (like a list of companies)
def create_seach_field(item_location)
  doc = Nokogiri::HTML(open(File.open(item_location)))
  doc.css('script').remove
  meta = ''
  search_string = ' ' + doc.css('title').text + "\n"
  begin
    meta = doc.css('meta[name=description]').attribute('content')
  rescue
  end
  search_string += meta
  search_string += Sanitize.fragment(doc.css('body').text)
  return search_string
end



def more_than_zero_is_one(x)
  if x > 0
    return 1
  else
    return 0
  end
end

def one_dimentionalize(array2d)
  oned = []
  array2d.each { |x| oned << x.first }
  return oned
end


# array[web_article][company]
def csv_to_array(csv)
  array = []
  File.open(csv).each_line do |line|
    array << line.to_s.gsub("\n","").split(',')
  end
  return array
end

#creating csv file contianing all occurances 
def create_raw_csv(html_dir, list_of_companies)

    
    
    array_of_companies = one_dimentionalize(csv_to_array(list_of_companies))
    
    #printing first line of csv file
    array_of_companies.each { |x| print ","+x }
    print "\n"
    
    
    Dir.foreach(html_dir) do |item|
      #puts item
      next if item == '.' or item == '..'
      item_location = html_dir+'/'+item

      link = File.open(item_location).read.lines.first.gsub('<!--','').gsub('-->','').gsub("\n",'')
      search_field = create_seach_field(item_location)
      
      #File.write(text_dir_name+'/'+item,search_field)
      #puts item
      print link 
      
      for i in 0 ... array_of_companies.size
	term = array_of_companies[i].downcase
	occurance_of_term = occurrence_counter(search_field.downcase,/[\t\r\ \n\(]#{term}[\.\ \,\n\)\!\?]/)
	print "," + occurance_of_term.to_s
      end
      
      print "\n"

      
      #regex to search for seperate word
      #counter_string = occurrence_counter(search_field.downcase,  /[\t\r\ \n\(]#{term}[\.\ \,\n\)\!\?]/)
      
      #puts link + ',' + counter_string.to_s
    end
end




=begin
sanitize does the following
 - remove companies that are not mentioned (NOT DONE)
 - only count single occurances of company names (NOT DONE)
 - remove occurances of companies that are talking about themselves (NOT DONE)
=end
# array[web_article][company]
def sanitize_csv(csv)
  two_d_array = csv_to_array(csv)
  #iterating through web articles
  for article in 1 ... two_d_array.size
    #iterating through companies
    for company in 1 ... two_d_array[0].size
      two_d_array[article][company] =  more_than_zero_is_one(two_d_array[article][company].to_i)
    end
  end
  return two_d_array
end

def help()
  puts ''
  puts 'HELP DOCUMENT'
  puts 'the options are:'
  puts ' - download_links [your+search+terms] [number of links you want (must be multiple of 10)]'
  puts ' - download_html [list of links] [destination directory]'
  puts ' - create_raw_csv [directory cointing html files to be searched] [csv file containing companie names to search for]'
  puts ' - sanitize_csv [raw csv]'
end


if ARGV[0] == '--help'
  help()
  
elsif ARGV[0] == 'download_links'
  if ARGV[1].nil? || ARGV[2].nil?
    puts oops
    help()
  else
    get_links(build_search_url(ARGV[1],''), (Integer(ARGV[2])/10))
    puts 'links downloaded'
  end
elsif ARGV[0] == 'download_html'
  if ARGV[1].nil? || ARGV[2].nil?
    puts oops
    help()
  else
    links_array = csv_to_array(ARGV[1])
    down_html_from_links_open_uri(links_array, ARGV[2])
  end
elsif ARGV[0] == 'create_raw_csv'
  if ARGV[1].nil? || ARGV[2].nil?
    puts oops
    help()
  else
    create_raw_csv(ARGV[1],ARGV[2])
  end
elsif ARGV[0] == 'sanitize_csv'
  if ARGV[1].nil?
    puts oops
    help()
  else
    print sanitize_csv(ARGV[1])
  end
else
  puts "you need to provide some arguments"
  help()
end




