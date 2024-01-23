class Truyenfull
  attr_reader :title_css, :html_content, :quotes

  def initialize
    @title_css = "a.chapter-title"
    @html_content = "div#chapter-c"
  end

  def get_title(document)
    title = document.css(@title_css)

    p title unless title.first
    title.first["title"] if title.first
  end

  def get_quotes(html_content)
    html_content.search("div").each { |src| src.remove }
    html_content.search("br").each { |src| src.remove }
    html_content.search("b").each { |src| src.remove }
    quotes = html_content.to_s.split("\"\"")
    quotes = quotes.reject { |q| q.empty? }

    quotes.map { |q| "<p>#{q}</p>" }
  end
end
