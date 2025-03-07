#!/usr/bin/env ruby

require 'yaml'
require 'json'


CHARACTERISTIC_MAP = {"M" => "might", "A" => "agility", "R" => "reason", "I"=> "intuition", "P" => "presence" }

def damage_clause(clause)
  types = ["acid", "cold", "corruption", "fire", "holy", "lightning", "poison", "psychic", "sonic"]
  attribute_match = clause.match(/\+ ([MARIP]) /)
  damage_addition = ""
  if attribute_match
    damage_addition = "+@chr"
  end
  split_string = clause.split(/[\s\+]/).reject{|e| e.nil? or e.empty?}
  type = types.find { |type|
    split_string.include? type
  }
  number = split_string[0]
  {
    "type": "damage",
    "types": [ type ],
    "value": "#{number}#{damage_addition}",
    "potency": potency_clause(clause),
    "display": ""
  }
end

def move_clause(clause)
  types = ["push", "slide", "pull"]
  split_string = clause.split(/[\s\+]/).reject{|e| e.nil? or e.empty?}
  type = types.find { |type|
    split_string.include? type
  }
  number = split_string[-1]
  {
    "type": "forced",
    "types": [ type ],
    "value": "#{number}",
    "potency": potency_clause(clause),
    "display": ""
  }
end

def effect_clause(clause)
  split_string = clause.split(/[\s\+]/).reject{|e| e.nil? or e.empty?}
  {
    "type": "ae",
    "potency": potency_clause(clause),
    "display": clause
  }
end

def potency_clause(clause)
  attribute_match = clause.match(/([MARIP]) \< (\w+), (.*)/)
  potency_characteristic = nil
  potency_level = nil
  potency_effect = nil
  if attribute_match
    potency_characteristic = attribute_match.captures[0]
    potency_level = attribute_match.captures[1]
    potency_effect = attribute_match.captures[2]
  end
  {
    "enabled": potency_characteristic ? true : false,
    "characteristic": CHARACTERISTIC_MAP[potency_characteristic],
    "value": potency_level ? "@potency.#{potency_level}" : nil,
    "display": potency_effect
  }
end

def parse_power_tier(input_tier)
  effects = []
  split_clauses = input_tier.split(/;/)
  split_clauses.each do |clause|
    split_clause = clause.split(/[\s\+]/).reject{|e| e.nil? or e.empty?}
    if split_clause.index("damage") == split_clause.length - 1
      effects << damage_clause(clause) 
    elsif split_clause.index{ |i| i in ["push", "slide", "pull"]}
      effects << move_clause(clause)
    else
      effects << effect_clause(clause)
    end
  end
  effects
end

def make_item(ability)
  {
  "name": ability["name"],
  "type": "ability",
  "img": "icons/svg/item-bag.svg",
  "system": {
    "description": {
      "value": "",
      "gm": "",
      "flavor": ability["description"]
    },
    "source": {
      "book": "",
      "page": "",
      "license": "",
      "revision": 1
    },
    "_dsid": ability["id"],
    "keywords": ability["keywords"].collect(&:downcase),
    "type": ability["type"]["usage"].downcase,
    "category": ability["cost"] == "signature" ? "signature" : "heroic",
    "resource": ability["cost"] == "signature" ? nil : ability["cost"],
    "trigger": "",
    "distance": {
      "type": ability["distance"][0]["type"].downcase,
      "primary": ability["distance"][0]["value"],
      "secondary": ability["distance"][0]["within"],
      "tertiary": nil
    },
    "damageDisplay": "melee",
    "target": {
      "type": ability["target"].split(' ')[1],
      "value": ability["target"].split(' ')[0]
    },
    "powerRoll": {
      "enabled": ability["powerRoll"] ? true : false,
      "formula": "@chr",
      "characteristics": ability["powerRoll"] ? ability["powerRoll"]["characteristic"].collect(&:downcase) : nil,
      "tier1": ability["powerRoll"] ? parse_power_tier(ability["powerRoll"]["tier1"]) : nil,
      "tier2": ability["powerRoll"] ? parse_power_tier(ability["powerRoll"]["tier2"]) : nil,
      "tier3": ability["powerRoll"] ? parse_power_tier(ability["powerRoll"]["tier3"]) : nil,
      "potencyCharacteristic": "reason"
    },
    "effect": ability["effect"]
  },
  "effects": [],
  "folder": nil,
  "flags": {},
  "_stats": {
    "compendiumSource": nil,
    "coreVersion": "12.331",
    "systemId": "draw-steel",
    "systemVersion": "0.6.2",
    "createdTime": 1740757635615,
    "modifiedTime": 1740757635615,
    "lastModifiedBy": "z2R22m76IkusoFkR"
  },
  "_id": "#{ability["id"]}",
  "sort": 0,
  "ownership": {
    "default": 0,
    "F1cSR286wTbtHGDL": 3
  },
  "_key": "!items!#{ability["id"]}!astring"
  }
  

end


#read_forge_file
Dir.glob('ForgeData/*.drawsteel-hero') do |filename|
  forge_file = File.read(filename)
  class_name = filename.split("/")[-1].split('.')[0].downcase
  output_dir_name = "./src/packs/#{class_name}abilities"
  parsed_forge_file = JSON.parse(forge_file)


  #pp "name"
  #pp parsed_forge_file["name"]
  #pp "ancestry name"
  #pp parsed_forge_file["ancestry"]["name"]
  #pp "--------------------class--------------------"
  #pp parsed_forge_file["class"].keys
  #pp "------------------selected-----------------------"
  #pp parsed_forge_file["class"]["featuresByLevel"].collect { |feature|
  #  feature["features"]
  #}

  #pp parsed_forge_file["class"]["abilities"].collect {|ability|
  #  ability["name"]
  #}

  items = parsed_forge_file["class"]["abilities"].collect do |ability|
    make_item(ability)
  end

  Dir.mkdir output_dir_name unless File.exist? output_dir_name
  items.each do |item|
    file = File.open("#{output_dir_name}/abilities_#{item[:name].gsub(/[\s,!]/, '_')}_#{item[:_id]}.json", "w+")
    file.write JSON.pretty_generate(item, {indent: "  ", object_nl: "\n", array_nl: "\n"})
  end
end

#db_file = File.open(output_file, "w+")
#db_file.write({"items" => items}.to_json)

#pp parsed_forge_file.keys


#parse_forge_file

#Make Foundry structure

#Fill in foundry structure

#Output


