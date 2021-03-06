require 'csv'
require 'active_fedora'

namespace :tufts_data do

  desc 'clean up Access.xml datastreams'
  task :clean_up_access_xml, [:arg1] => :environment do |t, args|
    if args[:arg1].nil?
      puts "YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!"
      puts "Usage: rake tufts_data:fix_election_records['/home/hydradm/path_to/list_of_pids.txt']"
      next
    end

    CSV.foreach(args[:arg1], encoding: "ISO8859-1") do |row|
      pid = row[0]
      begin
        record = TuftsBase.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
#        puts "ERROR Could not locate object: #{pid}"
        next
      end
      if record.kind_of?(Array)
#        puts "ERROR Multiple results for: #{pid}"
        next
      end

      begin

       unless record.datastreams['Access.xml'].nil? 
          #this was just a check for the Access.xml datastream
          #puts "#{pid} has Access.xml"
          
	  #this is a test of whether there are any cases where access datastream is equivalent to archival datastream
          #local_path = record.local_path_for("Access.xml")
          #local_path2 = record.local_path_for("Archival.pdf")
          #local_path3 = record.local_path_for("Archival.xml")
          #if (local_path == local_path2 ) || (local_path == local_path3)
          #  puts "CONFLICT #{record.pid}"
          #end

	  #archive the access.xml datastream
          #filename = record.local_path_for("Access.xml")
	  #dest_folder = '/home/hydradm/tufts/access_xml_archiving/'
          #FileUtils.cp(filename, dest_folder) 

          #delete files
          #filename = record.local_path_for("Access.xml")
          #dir = File.dirname(filename)
          #FileUtils.rm(filename)
          #puts "removing #{filename}"

          #if (Dir.entries(dir) - %w{ . .. }).empty?
          #  FileUtils.remove_dir(dir)
          #  puts "removing directory #{dir}"
          #else
          #  puts "directory not empty #{dir}"
          #end
          record.datastreams['Access.xml'].delete
          record.save!
       end
       
#       election_record.save!

#       election_record = TuftsVotingRecord.find(pid)

#       ds = election_record.create_datastream(ActiveFedora::Datastream,'RECORD-XML', ds_opts)

#       election_record.add_datastream ds

#       election_record.save!

      rescue => exception
        puts "ERROR There was an error doing the conversion for: #{pid}"
        puts exception.message
        puts exception.backtrace
        next
      end
    end 
  end

  def collection_code(pid)
    pid.sub(/.+:([^.]+).*/, '\1')
  end

  def pid_without_namespace(pid)
    pid.sub(/.+:(.+)$/, '\1')
  end

end
