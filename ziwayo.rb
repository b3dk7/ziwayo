#require 'json'
require 'watir'
require 'open-uri'
require 'nokogiri'
#require 'pismo'
require 'sanitize'

oops = 'oops, you seem to be missing arguments'

#with_date d w m y

#returns an array of links to investigate
def get_links(location, pages_to_crawl, name_of_links_file)
  list_of_links =[]
  b = Watir::Browser.new :chrome
  b.goto(location)
  for x in 0...pages_to_crawl
    for y in 1..10
      #puts y
      link = b.link id: 'title_'+(x*10+y).to_s
      list_of_links.push(link.href)
    end
    nxt = b.link href: 'javascript:document.nextform.submit();'
    nxt.exists?
    nxt.click
  end
  File.write(name_of_links_file, list_of_links)
end

#creates appropriate GET request
def build_search_url(search,date)
  url = 'https://www.startpage.com/do/search?query='+search+'&with_date='+date
  return url
end




def down_html_from_links_open_uri(links, dir_name)

  Dir.mkdir dir_name unless Dir.exist?(dir_name)

  for i in 0...links.length
    html_file = "<!--"+links[i]+"-->\n" + open(links[i]).read
    File.write(dir_name+'/'+i.to_s+'.html', html_file)
    puts 'downloaded index'+i.to_s
  end
  
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

def help()
  puts ''
  puts 'HELP DOCUMENT'
  puts 'the options are:'
  puts ' - download_links [your+search+terms] [number of links you want (must be multiple of 10)]'
  puts ' - download_html [list of links]'
  puts ' - search_dir [directory cointing html files to be searched]'
end


if ARGV[0] == '--help'
  help()
  
elsif ARGV[0] == 'download_links'
  if ARGV[1].nil? || ARGV[2].nil?
    puts oops
    help()
  else
    get_links(build_search_url(ARGV[1],''), (Integer(ARGV[2])/10), ARGV[1]+'.links')
    puts 'links downloaded'
  end
elsif ARGV[0] == 'download_html'
  if ARGV[1].nil?
    puts oops
    help()
  else
    links_array = read_array_from_disk(ARGV[1])
    down_html_from_links_open_uri(links_array, ARGV[1].gsub('.links',''))
  end
elsif ARGV[0] == 'search_dir'
  if ARGV[1].nil?
    puts oops
    help()
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
      counter_string = occurrence_counter(search_field.downcase,  /[\ \n\(]#{term}[\.\ \,\n\)\!\?]/).to_s
      
      puts counter_string
    end
  end
else
  puts "you need to provide some arguments"
  help()
end



