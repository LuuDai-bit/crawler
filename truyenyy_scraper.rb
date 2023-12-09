require 'httparty'
require 'nokogiri'

NUM_THREAD = 5
BATCH_SIZE = 100
LAST_CHAPTER = 546

def crawl_url(url, page_counter, dir)
  response = HTTParty.get(url, {
    headers: {
      "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"
    },
  })
  document = Nokogiri::HTML(response.body)

  return if page_counter == LAST_CHAPTER

  html_content = document.css("div#inner_chap_content_1")
  quotes = html_content.css("p")
  title = document.css("h2.heading-font.mt-2")
  chapter = title.inner_html
  chapter += quotes.map(&:to_s).join("\n")

  File.open(dir, "ab") do |f|
    f.write(chapter)
  end

  page_counter += 1

  next_url = "https://truyenyy.pro/truyen/theo-dai-thu-bat-dau-tien-hoa/chuong-#{page_counter}.html"

  [next_url, page_counter]
end

puts "Start crawling"

threads = (1..NUM_THREAD).map do |i|
  Thread.new(i) do |i|
    page_counter = (i-1) * BATCH_SIZE + 1
    url = "https://truyenyy.pro/truyen/theo-dai-thu-bat-dau-tien-hoa/chuong-#{page_counter}.html"
    dir = "results/tu_dai_thu_bat_dau_tien_hoa_#{i}.html"
    while true do
      page_counter = page_counter.nil? ? i : page_counter
      puts "#{page_counter}"

      url, page_counter = crawl_url(url, page_counter, dir)
      break if url.nil? || page_counter > (i * BATCH_SIZE)
    end
  end
end
threads.each { |t| t.join }

puts "Fisnish crawl"
