#######################################################################
#                                                                     #
#                  Bioinformatic challenges                           #
#                         Assignment 2                                #
#                    Rodrigo Álvarez Pardo                            #
#                                                                     #
#######################################################################

puts ""
puts "Importing the different modules...."
puts ""
require './Gene.rb'
require './Protein.rb'
require './PPI.rb'
require './InteractionNetwork.rb'
require 'net/http'

puts "NOTICE: This process can take a long time"
puts ""
puts "Sit back and relax"
puts ""

######################################################################

# Function that will be called from some objects to get data from an URI 

def uri_fetch(uri_str)
    address = URI(uri_str)  
    response = Net::HTTP.get_response(address)
    case response
      when Net::HTTPSuccess then  
        return response
    else
        abort "Something went wrong... the call to #{uri_str} failed; type #{response.class}"
    end
end

#################################################################
 
def write_record(networks, file)  # Function to write the report in the output file
  
  if File.exists?(file) 
    File.delete(file)             # We remove the file in case it exits to update it
  end
  
  ld = File.open(file, "a+")
  ld.puts "################################\n"
  ld.puts "Assigment 2 Report:\n"
  ld.puts "################################\n\n"
  ld.puts "\n______________________________________________________\n"
  networks.each do |id_net, network_obj|
    ld.puts ""
    ld.puts "Network number: #{id_net} -------> Number of nodes:#{network_obj.num_nodes}"
    ld.puts ""
    ld.puts "Genes associated and annotations:"
    network_obj.members.each do |id, gene|
      ld.puts "\t-- #{id}\n"
      gene.kegg.each do |kegg_id, kegg_name|
        ld.puts "\t\t\t\t KEGG Pathways ID: #{kegg_id};\tKEGG Pathways Name: #{kegg_name}"
        ld.puts ""
      end
      gene.go.each do |go_id, go_term_name|
        ld.puts "\t\t\t\t GO ID: #{go_id};\tGO Term Name: #{go_term_name}"
        ld.puts""
      end
    end
    ld.puts "\n______________________________________________________\n"
  end
  
  
  # The networks with 2 nodes, may not be considered as networks, we could also filter that
  
end
  
##################################################################

$MAX_LEVEL = 2 # We define in a global constant how deep we want to search in the interacting proteins


#################################################################


puts "Obtaining all interaccting proteins deeping #{$MAX_LEVEL.to_s} levels ..."
Gene.load_from_file('ArabidopsisSubNetwork_GeneList.txt')

###############################################################

$PPIS = PPI.all_ppis

def write_list_ppis (file)        # Class method to record the interactions between proteins
  
  if File.exists?(file) 
    File.delete(file)             # We remove the file in case it exits to update it
  end
  
  ld = File.open(file, "a+")
  ld.puts "List of all proteins interacting:"
    $PPIS.each do |prot|
      ld.puts "#{prot[0]} interacts whit #{prot[1]}"
    
    end
  
end

###########################################################

puts "DONE!\n\n"

##########################################################

puts "Obtaining networks ..."
Protein.all_prots_withintact.each do |id, prot_object|
  
  if not prot_object.network
    
    new_network = InteractionNetwork.create_network
    InteractionNetwork.assign(prot_object, new_network)
    # We call the recursive routine to explore the posible branches of the network
    
  end
  
end
##########################################################
puts "DONE!\n\n"

puts "Recording report..."
write_record(InteractionNetwork.all_networks,'Output.txt')
write_list_ppis("List of proteins interacting.txt")
puts "Task completed, output recorded in #{'Output.txt'} and #{"List of proteins interacting.txt"}"
  