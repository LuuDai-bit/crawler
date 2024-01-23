Dir["./template/*.rb"].each {|file| require file }

module ImportTemplate
  MAPPING = {
    "truyenyy": Truyenyy.new,
    "truyenfull": Truyenfull.new
  }
end
