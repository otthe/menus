#!/usr/bin/env ruby

require 'httparty'
require 'date'
require 'json'
require 'terminal-table'

class Menu
  #rt = restaurant
  def initialize(rt_id, rt_name, rt_lang="fi")
    @rt_id = rt_id.to_s
    @rt_name = rt_name
    @rt_lang = rt_lang

    @curr_time = DateTime.now.iso8601(3)
    @curr_time = @curr_time[0..-7] + "Z"
    @encoded_time = URI.encode_www_form_component(@curr_time)

    @url = "https://www.compass-group.fi/menuapi/day-menus?costCenter=#{@rt_id}&date=#{@encoded_time}&language=fi"

    @response = nil

    @meals = []
  end

  def fetch_data
    @response = HTTParty.get(@url)

    if @response.code == 200
      data = JSON.parse(@response.body)
      parse_data(data)
    else
      puts "failed to fetch data: #{@response.code}"
    end
  end

  def parse_data(data)
    puts "______________________________________________________"
    puts ""
    puts "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    puts "______________________________________________________"
    data["menuPackages"].map do |menu|
      name = menu["name"]

      if name != ""
        title = @rt_name.upcase + " / " + name.upcase
        rows = []
      
        if menu.key?("meals")
          menu["meals"].each do |meal|
            rows.push([meal["name"], meal["diets"].join(", ")])
          end
        end

        table = Terminal::Table.new :title => title, :headings => ['Ruoka', 'Merkinnät'], :rows => rows
        puts table
      end
    end
  end
end

if __FILE__ == $0
  lang="fi"
  menus = [
    Menu.new("0417", "carelia", lang),
    Menu.new("0433", "bistro", lang),
    #Menu.new("0413", "aura", lang),
    #Menu.new("041704", "futura", lang),
  ]

  threads = menus.map do |menu|
    Thread.new {menu.fetch_data}
  end

  threads.each(&:join)
end