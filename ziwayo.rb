require 'json'
require 'watir'
require 'open-uri'
require 'nokogiri'
require 'pismo'
require 'sanitize'


xxtest_array = ['https://en.wikipedia.org/wiki/Dude', 'https://en.wikipedia.org/wiki/GitHub']

xxtext = 'Sophos and Microsoft are really great companies that help defeat the wannacry virus. sophos is the best. brian is sophosticated'

xxkeywords = ['sophos','microsoft']

#with_date d w m y

#returns an array of links to investigate
def get_links(location, pages_to_crawl, name_of_links_file)
  list_of_links =[]
  b = Watir::Browser.new :chrome
  b.goto(location)
  for x in 0...pages_to_crawl
    for y in 1..10
      puts y
      link = b.link id: 'title_'+(x*10+y).to_s
      list_of_links.push(link.href)
    end
    nxt = b.link href: 'javascript:document.nextform.submit();'
    nxt.exists?
    nxt.click
  end
  File.write(name_of_links_file, list_of_links)
end

def build_search_url(search,date)
  url = 'https://www.startpage.com/do/search?query='+search+'&with_date='+date
  return url
end

def text_from_link(link)
  b = Watir::Browser.start link
  return b.text
end

def down_html_from_links_selenium(links, keyword)
  b = Watir::Browser.new :chrome
  Dir.mkdir keyword unless Dir.exist?(keyword)
  #b.start 'blank.html'
  for i in 0...links.length
    b.goto(links[i])
    File.write(keyword+'/'+i.to_s+'.html', b.html)
  end
  
end

def down_html_from_links_open_uri(links, dir_name)

  Dir.mkdir dir_name unless Dir.exist?(dir_name)

  for i in 0...links.length
    html_file = open(links[i]).read
    File.write(dir_name+'/'+i.to_s+'.html', html_file)
    puts 'downloaded index'+i.to_s
  end
  
end

def create_link_and_text_array(links)
  links_and_text_matrix=[]  
  for i in 0...links.length
    link_text_tuple=[2]
    link_text_tuple[0]=links[i]
    link_text_tuple[1] = text_from_link(links[i])
    links_and_text_matrix.push(link_text_tuple)
  end
  return links_and_text_matrix
end

def occurrence_counter(string, substring)
  return string.scan(/(?=#{substring})/).count
end



def read_array_from_disk(path)
  return JSON.parse(File.open(path).read)
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





=begin
COMMANDS

  *	download_links
  *	download_html
  *	search_dir
  
=end


if ARGV[0] == 'download_links'
  if ARGV[1].nil?
    puts 'you need to provide a search term, e.g. "neo+matrix"'
  else
    get_links(build_search_url(ARGV[1],''), 2, ARGV[1]+'.links')
    puts 'links downloaded'
  end
elsif ARGV[0] == 'download_html'
  if ARGV[1].nil?
    puts 'please provide a list of links to be downloaded'
  else
    links_array = read_array_from_disk(ARGV[1])
    down_html_from_links_open_uri(links_array, ARGV[1].gsub('.links',''))
  end
elsif ARGV[0] == 'search_dir'
  if ARGV[1].nil?
    puts 'please provide a directory to be searched and the search terms'
  else
    text_dir_name = ARGV[1]+'.text'
    Dir.mkdir text_dir_name unless Dir.exist?(text_dir_name)
    #note this iteration is not necesaraly in the order you want it to be - for now we dont care about the order
    Dir.foreach(ARGV[1]) do |item|
      #puts item
      next if item == '.' or item == '..'
      item_location = ARGV[1]+'/'+item
      
      search_field = create_seach_field(item_location)
      
      File.write(text_dir_name+'/'+item,search_field)
      #puts item
      term = 'root9B'
      #regex to search for seperate word
      counter_string = occurrence_counter(search_field.downcase,  /[\.\ \,\n\(\:]#{term}[\.\ \,\n\)\!\?]/).to_s
      
      puts counter_string
    end
  end

#doc = Nokogiri::HTML(open("http://www.threescompany.com/"))
end


#puts occurrence_counter("microsoft, microsoft and sophos and mmmmicrosoft microsoftttt", " microsoft ")


