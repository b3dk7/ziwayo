require 'watir'
require 'open-uri'
require 'nokogiri'
require 'sanitize'

oops = 'oops, you seem to be missing arguments'
#$matrix = []
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
  
  extract = ''
  
  doc = Nokogiri::HTML(open(File.open(item_location)))
  doc.css('script').remove
  doc.css('p').each do |paragraph|
    extract << paragraph.text.gsub('  ','').gsub("\n\n",'')
  end
  
  return extract
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

def array_to_csv(array)  
  array.each { |line| puts line.join(',')+"\n" }
end
def extract_domain(url)
  url = url.gsub('https://','').gsub('http://','')
  url = url[0...url.index('/')]
  url = url.gsub('www.','')
  return url
end
def remove_spaces_downcase(name)
  return name.gsub(' ','').downcase
end

=begin
sanitize does the following
 - only count single occurances of company names
 - remove occurances of companies that are talking about themselves
=end
def create_matrix(html_dir, list_of_companies)
    array_of_companies = one_dimentionalize(csv_to_array(list_of_companies))
    #printing first line of csv file
    print html_dir
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
	occurance_of_term = occurrence_counter(search_field.downcase,/[\t\r\ \n\(]#{term}[\-\'\.\ \,\n\)\!\?]/)
	#remove occurances of companies that are talking about themselves
	if extract_domain(link).include? remove_spaces_downcase(term)
	  print ",0"
	else
	
	  print "," + more_than_zero_is_one(occurance_of_term).to_s
	end
      end
      
      print "\n"

      
      #regex to search for seperate word
      #counter_string = occurrence_counter(search_field.downcase,  /[\t\r\ \n\(]#{term}[\.\ \,\n\)\!\?]/)
      
      #puts link + ',' + counter_string.to_s
    end
end








def sort_company_array(ca)
  #[2, 1, 3].sort_by{ |i| -i }
  return ca.sort_by{ |i| -i[1].size }
end

#company_array[company_num][company_name,[list_of_articles]]
def create_html(csv)
  
  
  company_array = []
  matrix= csv_to_array(csv)
  
  for company in 1 ... matrix[0].size
    list_of_articles = []
    for article in 1 ... matrix.size
      if matrix[article][company].to_i > 0
	list_of_articles << matrix[article][0]
      end
    end
    if list_of_articles.size > 0
      tuple = []
      tuple << matrix[0][company]
      tuple << list_of_articles
      
      company_array << tuple
    end
  end
  
  
  company_array = sort_company_array(company_array)
  
  
  html_file = File.open('html/output.html').read
  pietable = ""
  
  for c in 0...company_array.size
    pietable << '["' + company_array[c][0] + '",' + company_array[c][1].size.to_s + "],\n"
  end
  pietable = pietable[0...-2]
  
  
  all_companies=matrix[0].join(', ')[2..-1]
  all_articles =''
  
  matrix.each { |x| all_articles << x[0] }
  
  
  #fill in pietable
  html_file = html_file.sub('ziwayo{pie}',pietable)
  #fill in list of all companies and articles
  html_file = html_file.sub('ziwayo{all_companies}',all_companies)
  html_file = html_file.sub('ziwayo{all_articles}',all_articles)
  
  puts html_file
  
end
  

def help()
  puts ''
  puts 'HELP DOCUMENT'
  puts 'the options are:'
  puts ' - download_links [your+search+terms] [number of links you want (must be multiple of 10)]'
  puts ' - download_html [list of links] [destination directory]'
  puts ' - create_matrix [directory cointing html files to be searched] [csv file containing companie names to search for]'
  puts ' - create_html [matrix]'
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
elsif ARGV[0] == 'create_matrix'
  if ARGV[1].nil? || ARGV[2].nil?
    puts oops
    help()
  else
    
    create_matrix(ARGV[1],ARGV[2])
    
  end

elsif ARGV[0] == 'create_html'
  if ARGV[1].nil?
    puts oops
    help()
  else
    create_html(ARGV[1])
  end
else
  puts "you need to provide some arguments"
  help()
end




