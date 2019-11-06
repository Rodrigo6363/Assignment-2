
require 'net/http'
require 'json'
require './Protein.rb'
require 'rest-client'

#################################################
class Gene
  attr_accessor :gene_id            # The id of the genes taken from the file
  attr_accessor :prot_id            # The id of the proteins which is Unitprotid
  attr_accessor :kegg               # Hash that contains the kegg pathway id and the kegg pathway name
  attr_accessor :go                 # Hash that contains the go id and the go term name 
  @@total_gene_objects = Hash.new   # Class variable for capture in a hash all the instaces of Gene class and the key is the protein id
  
##################################################

  def initialize (params = {})
    
    @gene_id = params.fetch(:gene_id, "AT0G00000")
    @prot_id = params.fetch(:prot_id, "XXXXXX")
    @kegg = params.fetch(:kegg, Hash.new) 
    @go = params.fetch(:go, Hash.new) 
    
   # Class variable for capture in a hash all the instaces of Gene class and the key is the protein id
    @@total_gene_objects[prot_id] = self 
    
  end

#-###################################################

  def self.all_genes    # Class method to get the hash with all the instances of Gene object
    
    return @@total_gene_objects
  
  end

#####################################################

def self.fetch(url, headers = {accept: "*/*"}, user = "", pass="") # class method to have secure connection to the databases
  response = RestClient::Request.execute({
    method: :get,
    url: url.to_s,
    user: user,
    password: pass,
    headers: headers})
  return response
  
  rescue RestClient::ExceptionWithResponse => e
    $stderr.puts e.response
    response = false
    return response  
  rescue RestClient::Exception => e
    $stderr.puts e.response
    response = false
    return response 
  rescue Exception => e
    $stderr.puts e
    response = false
    return response  
end 

#####################################################

  def self.get_prot_id(gene_id)       # Class method to get the protein id [Unitprot] whit the api dbfetch
    
    res = fetch("http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=uniprotkb&id=#{gene_id}&format=default&style=raw&Retrieve=Retrieve");
  
  if res  
    body = res.body
    if body =~ /^ID\s+(\w+)/          # Regular expresion to match only the Unitprot id
      protein_id = $1
      #puts "The id is #{protein_id}"
      return protein_id
      else
    begin                             # A "begin" block to handle errors
      puts "There was no record" 
      raise "this is an error"        # raise an exception
    rescue 
      puts "exiting gracefully" 
    end
    end
  end
    
  end
    
#######################################################
   
  def self.load_from_file(filename) # Class Method to load the gene id from the file
      
    fg = File.open(filename, "r")
    
    fg.each_line do |line|
      
      line.delete!("\n")            # We remove end of line \n 
      
      protid = self.get_prot_id(line)
      
      Gene.new(
            :gene_id => line,
            :prot_id => protid
            )
      
      Protein.create_prot(protid, 0, gene_id = line) # We create Protein objects once we have the Gene object 
  
    end
    
    fg.close
  
  end

#######################################################

  def annotate  # Instance method that obtains (if present) kegg id , kegg pathway ,go id and go Term, and updates the object with them
    
    
    addressKEGG = URI("http://togows.org/entry/kegg-genes/ath:#{self.gene_id}/pathways.json")
    addressGO = URI("http://togows.org/entry/ebi-uniprot/#{self.gene_id}/dr.json")
    
    responseKEGG = Net::HTTP.get_response(addressKEGG)
    responseGO = Net::HTTP.get_response(addressGO)

    dataKEGG = JSON.parse(responseKEGG.body)
    dataGO = JSON.parse(responseGO.body)
    
    
    # Annotate with KEGG Pathways
    if dataKEGG[0]
      dataKEGG[0].each do |path_id, path_name|
        self.kegg[path_id] = path_name 
      end
    end
    
    
    # Annotate with GO
    if dataGO[0]["GO"]
      dataGO[0]["GO"].each do |num|
        if num[1] =~ /^P:/                        # We must check the go refers to a biological proccess 
          self.go[num[0]] = num[1].sub(/P:/, "") 
        end 
      end  
    end
    
    
  end
  
##########################################################
  
end