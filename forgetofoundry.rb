#!/usr/bin/env ruby

require 'yaml'
require 'json'
require 'securerandom'


CHARACTERISTIC_MAP = {"M" => "might", "A" => "agility", "R" => "reason", "I"=> "intuition", "P" => "presence" }

def create_damage_effect(clauses)
  id = random_id
  {id =>
   {
    "type": "damage",
    "_id": id,
    "_key": id,
    "name": "",
    "damage": {
      "tier1": clauses["tier1"] ? damage_clause(clauses["tier1"]) : nil,
      "tier2": clauses["tier2"] ? damage_clause(clauses["tier2"]) : nil,
      "tier3": clauses["tier3"] ? damage_clause(clauses["tier3"]) : nil
    }
   }
  }
end

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
    "types": [ type ].compact,
    "value": "#{number}#{damage_addition}",
    "potency": potency_clause(clause),
    "display": ""
  }
end

def create_move_effect(clauses)
  id = random_id
  {id =>
   {
    "type": "forced",
    "_id": id,
    "_key": id,
    "name": "",
    "forced": {
      "tier1": clauses["tier1"] ? move_clause(clauses["tier1"]) : nil,
      "tier2": clauses["tier2"] ? move_clause(clauses["tier2"]) : nil,
      "tier3": clauses["tier3"] ? move_clause(clauses["tier3"]) : nil
    }
   }
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
    "movement": [ type ],
    "distance": "#{number}",
    "display": "{{forced}}"
  }
end

def create_applied_effect(clauses)
  id = random_id
  {id =>
   {
    "type": "applied",
    "_id": id,
    "_key": id,
    "name": "",
    "applied": {
      "tier1": clauses["tier1"] ? effect_clause(clauses["tier1"]) : nil,
      "tier2": clauses["tier2"] ? effect_clause(clauses["tier2"]) : nil,
      "tier3": clauses["tier3"] ? effect_clause(clauses["tier3"]) : nil
    }
   }
  }

end

def effect_clause(clause)
  split_string = clause.split(/[\s\+]/).reject{|e| e.nil? or e.empty?}
  {
    "potency": potency_clause(clause),
    "display": clause
  }
end

def potency_clause(clause)
  attribute_match = clause.match(/([MARIP]) \< \[(\w+)\], (.*)/)
  potency_characteristic = nil
  potency_level = nil
  potency_effect = nil
  if attribute_match
    potency_characteristic = attribute_match.captures[0]
    potency_level = attribute_match.captures[1]
    potency_effect = attribute_match.captures[2]
  end
  {
    "characteristic": CHARACTERISTIC_MAP[potency_characteristic],
    "value": potency_level ? "@potency.#{potency_level}" : nil,
  }
end

def parse_effects(input_roll)
  effects = {}
  clauses = {damage: {exists: false}, 
             move: {exists: false}, 
             applied:{exists: false}
  }
  ["tier1", "tier2", "tier3"].each do |tier|
    split_clauses = input_roll[tier].split(/;/)
    split_clauses.each do |clause|
      split_clause = clause.split(/[\s\+]/).reject{|e| e.nil? or e.empty?}
      if split_clause.index("damage") == split_clause.length - 1
        clauses[:damage][:exists] = true  
        clauses[:damage][tier] = clause
      elsif split_clause.index{ |i| ["push", "slide", "pull"].include? i }
        clauses[:move][:exists] = true  
        clauses[:move][tier] = clause
      else
        clauses[:applied][:exists] = true  
        clauses[:applied][tier] = clause
      end
    end
  end
  if clauses[:damage][:exists] == true
    effects.merge! create_damage_effect(clauses[:damage])
  end
  if clauses[:move][:exists]== true
    effects.merge! create_move_effect(clauses[:move])
  end
  if clauses[:applied][:exists] == true
    effects.merge! create_applied_effect(clauses[:applied])
  end
  return effects
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

def parse_target(target_string)
  str_to_int_hash = {
    'one'   => 1,
    'two'   => 2,
    'three' => 3,
    'four'  => 4,
    'five'  => 5,
    'six'   => 6,
    'seven' => 7,
    'eight' => 8,
    'nine'  => 9,
    'ten'   => 10,
    'all'   => 10
  }
  type = target_string.split(' ')[1]
  value = target_string.split(' ')[0]
  if value && value.to_i.to_s != value
    value = str_to_int_hash[value.downcase]
  end
  {
    "type": type,
    "value": value
  }
end

def distance_clause(distances)
  if distances.length > 0
    if distances.length > 1 and distances[0]["type"] == "Melee" and distances[1]["type"] == "Ranged"
      distanceType = "meleeRanged"
      secondary = distances[1]["value"]
    else
      distanceType = distances[0]["type"].downcase
      secondary = distances[0]["within"]
    end
    {"distance": {
        "type": distanceType,
        "primary": distances[0]["value"],
        "secondary": secondary,
        "tertiary": nil
      }
    }
  else
    {}
  end
end

def make_item(ability, monster_id=nil)
  clean_ability_id = cleaned_id(ability["id"])
  key = monster_id ? "!actors.items!#{monster_id}.#{clean_ability_id}" : "!items!#{ability["id"]}!astring"
  item_key = {"_key": key,
              "_id": monster_id ? clean_ability_id : clean_ability_id
  }
  cost = if ability["cost"] == "signature" || ability["cost"] == 0
           { "category": "signature", "resource":  nil}
          else
           { "category": "heroic", "resource":  ability["cost"]}
          end
  item = {
  "name": ability["name"],
  "type": "ability",
  "img": "icons/svg/item-bag.svg",
  "system": {
    "source": {
      "book": "",
      "page": "",
      "license": "",
      "revision": 1
    },
    "_dsid": ability["id"],
    "keywords": ability["keywords"].collect(&:downcase),
    "type": ability["type"]["usage"].downcase,
    **cost,
    "trigger": "",
    **distance_clause(ability["distance"]),
    "damageDisplay": "melee",
    "target": parse_target(ability["target"]),
    "power": {
      "roll": {
        "formula": "@chr",
        "characteristics": ability["powerRoll"] ? ability["powerRoll"]["characteristic"].collect(&:downcase) : nil
      },
      "effects": ability["powerRoll"] ? parse_effects(ability["powerRoll"]) : nil
    },
    "effect": {
      "before": "",
      "after": ability["effect"],
    },
    "spend": {
      "value": nil,
      "text": ""
    },
    "story": ability["description"]
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
  "sort": 0,
  "ownership": {
    "default": 0,
    "F1cSR286wTbtHGDL": 3
  },
  }
  item = item.merge(item_key)
  return item  
end

def make_monster(monster, monster_group_folder_id)
  id = cleaned_id(monster["id"])
  return {"name": monster["name"],
   "_dsid": id,
   "type": "npc",
   "img": "icons/svg/mystery-man.svg",
   "system": {
      "stamina": {
        "value": monster["stamina"],
        "max": monster["stamina"],
        "temporary": nil
      },
      "characteristics": {
        "might": {
          "value": monster["characteristics"].detect do |item|
            item["characteristic"] == "Might"
          end["value"]
        },
        "agility": {
          "value": monster["characteristics"].detect do |item|
            item["characteristic"] == "Agility"
          end["value"]
        },
        "reason": {
          "value": monster["characteristics"].detect do |item|
            item["characteristic"] == "Reason"
          end["value"]
        },
        "intuition": {
          "value": monster["characteristics"].detect do |item|
            item["characteristic"] == "Intuition"
          end["value"]
        },
        "presence": {
          "value": monster["characteristics"].detect do |item|
            item["characteristic"] == "Presence"
          end["value"]
        }

      },
      "combat": {
        "size": {
            "value": monster["size"]["value"],
            "letter": monster["size"]["mod"]
        },
        "stability": monster["stability"],
        "turns": 1
      },
      "biography": {
        "value": "",
        "gm": "",
        "languages": []
      },
      "movement": monster_movement(monster),
      "damage": monster_damage_immunities(monster),
      "source": {
        "book": "",
        "page": "",
        "license": "",
        "revision": 1
      },
      "negotiation": {
        "interest": 5,
        "patience": 5,
        "motivations": [],
        "pitfalls": [],
        "impression": 1
      },
      "monster": {
        "freeStrike": monster["freeStrikeDamage"],
        "keywords": monster["keywords"],
        "level": monster["level"],
        "ev": monster["encounterValue"],
        "role": monster["role"]["type"].downcase,
        "organization": monster["role"]["organization"].downcase
      }
    },
    "items": monster["features"].collect do |item|
      make_monster_item(item, id)
    end.compact,
    "effects": [],
    "ownership": {
      "default": 0,
      "F1cSR286wTbtHGDL": 3
    },
    "prototypeToken": {
      "name": monster["name"],
      "displayName": 0,
      "actorLink": false,
      "appendNumber": false,
      "prependAdjective": false,
      "width": 1,
      "height": 1,
      "texture": {
        "src": "icons/svg/mystery-man.svg",
        "anchorX": 0.5,
        "anchorY": 0.5,
        "offsetX": 0,
        "offsetY": 0,
        "fit": "contain",
        "scaleX": 1,
        "scaleY": 1,
        "rotation": 0,
        "tint": "#ffffff",
        "alphaThreshold": 0.75
      },
      "hexagonalShape": 0,
      "lockRotation": false,
      "rotation": 0,
      "alpha": 1,
      "disposition": -1,
      "displayBars": 50,
      "bar1": {
        "attribute": "stamina"
      },
      "bar2": {
        "attribute": "hero.resources"
      },
      "light": {
        "negative": false,
        "priority": 0,
        "alpha": 0.5,
        "angle": 360,
        "bright": 0,
        "color": nil,
        "coloration": 1,
        "dim": 0,
        "attenuation": 0.5,
        "luminosity": 0.5,
        "saturation": 0,
        "contrast": 0,
        "shadows": 0,
        "animation": {
          "type": nil,
          "speed": 5,
          "intensity": 5,
          "reverse": false
        },
        "darkness": {
          "min": 0,
          "max": 1
        }
      },
      "sight": {
        "enabled": false,
        "range": 0,
        "angle": 360,
        "visionMode": "basic",
        "color": nil,
        "attenuation": 0.1,
        "brightness": 0,
        "saturation": 0,
        "contrast": 0
      },
      "detectionModes": [
        {
          "id": "lightPerception",
          "range": nil,
          "enabled": true
        }
      ],
      "occludable": {
        "radius": 0
      },
      "ring": {
        "enabled": false,
        "colors": {
          "ring": nil,
          "background": nil
        },
        "effects": 1,
        "subject": {
          "scale": 1,
          "texture": nil
        }
      },
    },
    "folder": monster_group_folder_id,
    "_id": id,
    "_key": "!actors!#{id}"
  }
end

def monster_movement(monster)
  {
    "walk": monster["speed"]["value"],
    "burrow": nil,
    "climb": nil,
    "swim": nil,
    "fly": nil,
    "teleport": nil
  }
end

def monster_damage_immunities(monster)
  current_immunities = {
    "immunities": {
      "all": 0,
      "acid": 0,
      "cold": 0,
      "corruption": 0,
      "fire": 0,
      "holy": 0,
      "lightning": 0,
      "poison": 0,
      "psychic": 0,
      "sonic": 0
    },
    "weaknesses": {
      "all": 0,
      "acid": 0,
      "cold": 0,
      "corruption": 0,
      "fire": 0,
      "holy": 0,
      "lightning": 0,
      "poison": 0,
      "psychic": 0,
      "sonic": 0
    }
  }
  immunities = monster["features"].each do |item|
    if item["type"] == "Damage Modifier"
      item["data"]["modifiers"].each do |modifier|
        if modifier["type"] == "Immunity"
          current_immunities[:immunities][modifier["damageType"].downcase.to_sym] = modifier["value"]
        end
      end
    end
  end
  current_immunities
end

def cleaned_id(id)
  clean_item_id = id.gsub('-','').ljust(16,'a')
  clean_item_id = clean_item_id[-16..-1] || clean_item_id
  return clean_item_id
end

def random_id()
  SecureRandom.alphanumeric(16)
end

def make_monster_item(item, monster_id)
    if item["type"] == "Ability"
      return make_item(item["data"]["ability"], monster_id)
    end
    if item["type"] == "Damage Modifier"
      return nil
    end
    if item["type"] == "Text"
      clean_item_id = cleaned_id(item["id"])
      return { 
        "name": item["name"],
        "type": "feature",
        "img": "icons/svg/item-bag.svg",
        "system": {
          "description": {
            "value": item["description"],
          }
        },
        "_dsid": item["id"],
        "_id": clean_item_id,
        "_key": "!actors.items!#{monster_id}.#{clean_item_id}"
      }
    end
    pp "****nonabilityitem****"
    pp item
    {
      "name": item["name"],
      "type": "feature",
      "system": {
        "description": {
          "value": item["description"],
          "gm": ""
        },
#       "source": {
#         "book": "",
#         "page": "",
#         "license": "",
#         "revision": 1
#       },
        "type": {
          "value": "",
          "subtype": ""
        },
        "prerequisites": {
          "value": ""
        }
      },
      "effects": []
    }
end

def output_items(items, output_dir_name)
  Dir.mkdir output_dir_name unless File.exist? output_dir_name
  items.each do |item|
    name = item[:name] || item["name"]
    dsid = item[:_dsid] || item["_dsid"]
    file = File.open("#{output_dir_name}/abilities_#{name.gsub(/[\s,!]/, '_')}_#{dsid}.json", "w+")
    file.write JSON.pretty_generate(item, {indent: "  ", object_nl: "\n", array_nl: "\n"})
  end
end

def make_monster_folder(folder_name, folder_id)
  output_dir_name = "./src/packs/monsters/#{folder_name}"
  Dir.mkdir output_dir_name unless File.exist? output_dir_name
  folder_json = {
    "_id": folder_id,
    "_key": "!folders!#{folder_id}",
    "name": folder_name,
    "type": "Actor",
    "sorting": "a"
  }
  file = File.open("#{output_dir_name}/_Folder.json", "w+")
  file.write JSON.pretty_generate(folder_json, {indent: "  ", object_nl: "\n", array_nl: "\n"})
end

def output_monsters(items, monster_group)
  output_dir_name = "./src/packs/monsters/#{monster_group}"
  Dir.mkdir output_dir_name unless File.exist? output_dir_name
  items.each do |item|
    file = File.open("#{output_dir_name}/npc_#{item[:name].gsub(/[\s,!]/, '_')}_#{item[:_id]}.json", "w+")
    file.write JSON.pretty_generate(item, {indent: "  ", object_nl: "\n", array_nl: "\n"})
  end

end


#read_forge_file
forge_file = File.read('ForgeData/core.drawsteel-sourcebook')
parsed_forge_file = JSON.parse(forge_file)
parsed_forge_file["classes"].each do |aclass|
  class_name = aclass["name"].downcase
  output_dir_name = "./src/packs/#{class_name}abilities"
  items = aclass["abilities"].collect do |ability|
    make_item(ability)
  end

  items += aclass["featuresByLevel"].collect do |level|
    level["features"].select{|feature| feature["type"] == "Ability"}.collect do |ability|
      make_item(ability["data"]["ability"])
    end
  end

  items += aclass["subclasses"].collect do |subclass|
    subclass["featuresByLevel"].collect do |level|
      choices = level["features"].select{|feature| feature["type"] == "Choice"}.collect do |choice|
        choice["data"]["options"].collect do |option|
          make_item(option["feature"]["data"]["ability"])
        end
      end
      features = level["features"].select{|feature| feature["type"] == "Ability"}.collect do |ability|
        make_item(ability["data"]["ability"])
      end
      choices + features
    end
  end

  output_items(items.flatten, output_dir_name)
end

parsed_forge_file["kits"].each do |kit|
  kit_name = kit["name"].downcase
  output_dir_name = "./src/packs/kits"
  items = kit["features"].collect do |ability|
    make_item(kit["features"][0]["data"]["ability"])
  end

  output_items(items, output_dir_name)
end

basic_ability_files = Dir['ForgeData/*'] - Dir['ForgeData/core.drawsteel-sourcebook']
basic_abilities = []
basic_ability_files.each do |file|
  ability = JSON.parse(File.read(file))
  basic_abilities << ability
end
output_dir_name = "./src/packs/basic"
output_items(basic_abilities, output_dir_name)

#db_file = File.open(output_file, "w+")
#db_file.write({"items" => items}.to_json)

parsed_forge_file["monsterGroups"].each do |monster_group|
  monster_group_folder_id = monster_group["name"].downcase.gsub(/[^0-9a-z]/, '').ljust(17,'a')[0..15]
  make_monster_folder(monster_group["name"].downcase, monster_group_folder_id)
  monsters = monster_group["monsters"].collect do |monster|
    make_monster(monster, monster_group_folder_id)
  end
  output_monsters(monsters, monster_group["name"].downcase)
end


#pp parsed_forge_file.keys


#parse_forge_file

#Make Foundry structure

#Fill in foundry structure

#Output


