# ruby truyenyy_scraper.rb truyenyy

require 'httparty'
require 'nokogiri'
require './import_template'

BATCH_SIZE = 100
FIRST_CHAPTER = 201
LAST_CHAPTER = 600
DEFAULT_HEADER = {
    "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"
  }.freeze

def crawl_url(url, page_counter, dir, template)
  response = HTTParty.get(url, {
    headers: DEFAULT_HEADER,
  })
  document = Nokogiri::HTML(response.body)

  return if page_counter > LAST_CHAPTER

  html_content = document.css(template.html_content)
  quotes = template.get_quotes(html_content) || html_content.css(template.quotes)
  title = template.get_title(document) || document.css(template.title_css)
  chapter = title.to_s
  chapter += quotes.map(&:to_s).join("\n")

  File.open(dir, "ab") do |f|
    f.write(chapter)
  end

  page_counter += 1

  next_url = "https://truyenfull.vn/co-chan-nhan/chuong-#{page_counter}/"

  [next_url, page_counter]
end

# Handle params
site = ARGV[0]

puts "Start crawling"

template = ImportTemplate::MAPPING[site.to_sym]
num_thread = ((LAST_CHAPTER - FIRST_CHAPTER + 1) / BATCH_SIZE).ceil
threads = (1..num_thread).map do |i|
  Thread.new(i) do |i|
    page_counter = (i-1) * BATCH_SIZE + FIRST_CHAPTER
    url = "https://truyenfull.vn/co-chan-nhan/chuong-#{page_counter}/"
    dir = "results/co_chan_nhan#{(FIRST_CHAPTER / BATCH_SIZE).floor + i}.html"

    File.open(dir, "wb") do |f|
      f.write("<html>\n<body>")
    end

    while true do
      page_counter = page_counter.nil? ? i : page_counter
      puts "#{page_counter}"

      url, page_counter = crawl_url(url, page_counter, dir, template)
      break if url.nil? || page_counter > (i * BATCH_SIZE + FIRST_CHAPTER - 1)
    end

    File.open(dir, "ab") do |f|
      f.write("</body>\n</html>")
    end
  end
end
threads.each { |t| t.join }

puts "Fisnish crawl"
