require 'httparty'
require 'nokogiri'

# Define data structure
PokemonProduct = Struct.new(:url, :image, :name, :price)

def crawl_url(url, page_counter, dir)
  response = HTTParty.get(url, {
    headers: {
      "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"
    },
  })
  document = Nokogiri::HTML(response.body)
  html_products = document.css("li.product")
  html_not_found = document.at_css("div.error-404")

  return if html_not_found

  pokemon_products = []
  html_products.each do |html_product|
    url = html_product.css("a").first.attribute("href").value
    image = html_product.css("img").first.attribute("src").value
    name = html_product.css("h2").first.text
    price = html_product.css("span").first.text

    pokemon_product = PokemonProduct.new(url, image, name, price)

    pokemon_products.push(pokemon_product)
  end

  CSV.open(dir, "ab", write_headers: true) do |csv|
    pokemon_products.each do |pokemon_product|
      csv << pokemon_product
    end
  end

  page_counter = page_counter.nil? ? 2 : (page_counter + 1)

  ["https://scrapeme.live/shop/page/#{page_counter}/", page_counter]
end

puts "Start crawling"

threads = (1..4).map do |i|
  Thread.new(i) do |i|
    page_counter = (i-1) * 10 + 1
    url = "https://scrapeme.live/shop/page/#{page_counter}/"
    dir = "results/output#{i}.csv"
    while true do
      page_counter = page_counter.nil? ? i : page_counter
      puts "#{page_counter}"

      url, page_counter = crawl_url(url, page_counter, dir)
      break if url.nil? || page_counter > (i * 10)
    end
  end
end
threads.each { |t| t.join }

puts "Fisnish crawl"
