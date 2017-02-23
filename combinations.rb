require 'csv'

pointcosts = {Ackbar: [0,10,14],
                Leia: [0,12,16],
                Poe: [0,14,18],
                RT: [0,8,16,24],
                Luke: [0,15,20],
                Pada: [0,8,16,24],
                QGJ: [0,13,17],
                Rey: [0,9,12],
                Finn: [0,13,16],
                Han: [0,14,18],
                HG: [0,8,16,24],
                Padme: [0,10,14]}

possiblecount = {Ackbar: (0..2).to_a,
                   Leia: (0..2).to_a,
                   Poe: (0..2).to_a,
                   RT: (0..3).to_a,
                   Luke: (0..2).to_a,
                   Pada: (0..3).to_a,
                   QGJ: (0..2).to_a,
                   Rey: (0..2).to_a,
                   Finn: (0..2).to_a,
                   Han: (0..2).to_a,
                   HG: (0..3).to_a,
                   Padme: (0..2).to_a}
=begin

pointcosts = {Phasma: [0,12,15],
              FOS: [0,7,14,21,28],
              GG: [0,13,18],
              Veers: [0,11,14],
              Dooku: [0,11,15],
              Vader: [0,16,21],
              Kylo: [0,10,13],
              NS: [0,8,16,24],
              Bala: [0,8,11],
              Jabba: [0,11,14],
              Jango: [0,12,16],
              TR: [0,9,18,27]}

possiblecount = {Phasma: (0..2).to_a,
                   FOS: (0..4).to_a,
                   GG: (0..2).to_a,
                   Veers: (0..2).to_a,
                   Dooku: (0..2).to_a,
                   Vader: (0..2).to_a,
                   Kylo: (0..2).to_a,
                   NS: (0..3).to_a,
                   Bala: (0..2).to_a,
                   Jabba: (0..2).to_a,
                   Jango: (0..2).to_a,
                   TR: (0..3).to_a}

pointcosts = {Phasma: [0,12,15],
              FOS: [0,7,14,21,28],
              GG: [0,13,18]}

possiblecount = {Phasma: (0..2).to_a,
                   FOS: (0..4).to_a,
                   GG: (0..2).to_a}
=end

#############################################################
# Create baseline combinations
# -- gives every single combination of characters possible --
# -- this will be filtered and shaved down later

def product_hash(hsh)
  attrs   = hsh.values
  keys    = hsh.keys
  product = attrs[0].product(*attrs[1..-1])
  product.map{ |p| Hash[keys.zip p] }
end

possibilities = product_hash(possiblecount)

#############################################################
# Give each possibility a Dice count, a total point count, 
# and a unique ID used to find only the most efficient
# combinations

possibilities.each_with_index do |p,i|
  rowsum = 0
  combination_id = ""
  team_name = ""
  possibilities[i][:charactercount] = p.values.inject(:+) #sums the dice in current row
  p.each do |k, v|
    next if k.to_s == "charactercount"
    rowsum += pointcosts[k.to_sym][v]
    combination_id += (v > 0 ? 1 : 0).to_s
    team_name += k.to_s + v.to_s + " " if v > 0
  end
  possibilities[i][:totalpoints] = rowsum
  possibilities[i][:combination_id] = combination_id.to_i
  possibilities[i][:team_name] = team_name.strip
end

#############################################################
# Filtering and removal

# remove all entries that aren't between 1 and 4 characters
# and those that aren't between 24 and 30 points
# 24 being the minimum as at 23 you could add another Trooper
possibilities.reject! { |h| !h[:charactercount].between?(0,4) || !h[:totalpoints].between?(24,30) }

#sort the possibilities first by ID, then by dice count ascending
possibilities.sort_by! { |h| [h[:combination_id],-h[:charactercount]] }

#checks if team is most efficient
possibilities.each_index do |i|
  if i == 0
    possibilities[i][:status] = "KEEP"
    next
  end
  if possibilities[i-1][:combination_id] == possibilities[i][:combination_id]
    possibilities[i][:status] = possibilities[i-1][:charactercount] <= possibilities[i][:charactercount] ? possibilities[i-1][:status] : "TOSS"
  else
    possibilities[i][:status] = "KEEP"
  end
end

#delete inefficient teams
possibilities.delete_if { |h| h[:status] == "TOSS" }

#remove staus column
possibilities.each { |h| h.delete(:status) }

#export to CSV
CSV.open("data.csv", "wb") do |csv|
  csv << possibilities.first.keys # adds the attributes name on the first line
  possibilities.each do |hash|
    csv << hash.values
  end
end