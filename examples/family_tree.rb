dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require File.join(dir, 'happymapper')

file_contents = File.read(dir + '/../spec/fixtures/family_tree.xml')

module FamilySearch
  class AlternateIds
    include HappyMapper
    
    tag 'alternateIds'
    namespace 'fsapi-v1' => 'http://api.familysearch.org/v1'
    has_many :ids, String, :tag => 'id'
  end
  
  class Information
    include HappyMapper
    
    namespace 'fsapi-v1' => 'http://api.familysearch.org/v1'
    has_one :alternateIds, AlternateIds
  end
  
  class Person
    include HappyMapper
    
    namespace_url 'http://api.familysearch.org/familytree/v1'
    attribute :version, String
    attribute :modified, Time
    attribute :id, String
    has_one :information, Information
  end
  
  class Persons
    include HappyMapper
    
    namespace_url 'http://api.familysearch.org/familytree/v1'
    has_many :person, Person
  end
  
  class FamilyTree
    include HappyMapper
    
    tag 'familytree'
    namespace_url 'http://api.familysearch.org/familytree/v1'
    attribute :version, String
    attribute :status_message, String, :tag => 'statusMessage'
    attribute :status_code, String, :tag => 'statusCode'
    has_one :persons, Persons
  end
end

familytree = FamilySearch::FamilyTree.parse(file_contents)
familytree.persons.person.each do |p|
  puts p.id, p.information.alternateIds.ids, ''
end
puts familytree.to_xml