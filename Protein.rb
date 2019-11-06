
require 'net/http'
require 'json'
require './PPI.rb'

##################################################
class Protein
  attr_accessor :prot_id                      # UniProt id
  attr_accessor :intact_id                    # IntAct id for proteins that interacts
  attr_accessor :network                      # Network id 
  @@total_protein_objects = Hash.new          # Class variable for capture in a hash all the instaces of protein and the key is the protein id
  @@total_protwithintact_objects = Hash.new   # Class variable for capture in a hash all the instaces of protein and the key is the intact id
  
###################################################

  def initialize (params = {})
    
    @prot_id = params.fetch(:prot_id, "XXXXXX") 
    @intact_id = params.fetch(:intact_id, nil)
    @network = params.fetch(:network, nil)
    
    @@total_protein_objects[prot_id] = self
    
    if intact_id
      @@total_protwithintact_objects[intact_id] = self
    end  
    
  end
  
#####################################################

  def self.all_prots  # Class method to get the hash with all the instances of protein object
     
    return @@total_protein_objects
  
  end

######################################################

  def self.all_prots_withintact   # Class method to get the hash with all the instances of protein object with key the intact id
   
    
    return @@total_protwithintact_objects
  
  end

######################################################  

  def self.create_prot (prot_id, level, gene_id = nil, intact = nil)  # Class method that creates a protein object, given its protein id and the level of interaction depth
    
    if not intact                                                     # If the intact id is not given, we look if the protein has it
      intact = self.get_prot_intactcode(gene_id) 
    end

    if intact && (level < $MAX_LEVEL)                                 # When we know the protein has an intact id, we look for the interacting proteins
     
      PPI.create_ppis(intact, level)
    end
    
    Protein.new(
            :prot_id => prot_id,
            :intact_id => intact,
            :network => nil                                            # We establish network relationships as empty
            )
      

    level += 1                                                         # We deep one level more
    
  end
  
######################################################

  def self.exists(intact_id)  # class method that checks if with a given intact id the protein instance has been created
    
    if @@total_protwithintact_objects.has_key?(intact_id)
      return true
    
    else
      return false
    
    end
    
  end
  
###########################################################

#def self.fetch(url, headers = {accept: "*/*"}, user = "", pass="")  # class method to have secure connection to the databases
#  response = RestClient::Request.execute({
#    method: :get,
#    url: url.to_s,
#    user: user,
#    password: pass,
#    headers: headers})
#  return response
#  
#  rescue RestClient::ExceptionWithResponse => e
#    $stderr.puts e.response
#    response = false
#    return response  
#  rescue RestClient::Exception => e
#    $stderr.puts e.response
#    response = false
#    return response 
#  rescue Exception => e
#    $stderr.puts e
#    response = false
#    return response  
#end 

######################################################

  def self.get_prot_intactcode(gene_id)  # Class method that searchs whether a given protein is present in IntAct database or not
    
    address = URI("http://togows.org/entry/ebi-uniprot/#{gene_id}/dr.json")
    response = Net::HTTP.get_response(address)
    
    data = JSON.parse(response.body)
    
    if data[0]['IntAct']
      return data[0]['IntAct'][0][0] 
    else
      return nil
    end


  end

########################################################

  def self.intactcode2protid(intact_accession_code)                                                     # Class method to obtain the unitprot id given a protein intact accession code
    
    
    intact_accession_code.delete!("\n")
    
    if intact_accession_code =~ /[OPQ][0-9][A-Z0-9]{3}[0-9]|[A-NR-Z][0-9]([A-Z][A-Z0-9]{2}[0-9]){1,2}/  # Regular expression obtained from "https://www.uniprot.org/help/accession_numbers"
     
      
      
      begin
        
        address = URI("http://togows.org/entry/ebi-uniprot/#{intact_accession_code}/entry_id.json")
        response = Net::HTTP.get_response(address)
  
        data = JSON.parse(response.body)

        return data[0]
      
      rescue
        return "UniProt ID not found"      
      
      end
    
    else
      
      return "UniProt ID not found"
    
    end
    
  end
  
##########################################################




end