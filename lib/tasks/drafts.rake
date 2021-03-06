require 'csv'
require 'active_fedora'

namespace :tufts_data do

  desc 'create drafts from tufts objects'
  task :create_drafts, [:arg1] => :environment do |t, args|
    if args[:arg1].nil?
      puts "YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!"
      puts "Usage: rake tufts_data:create_drafts['/home/hydradm/path_to/list_of_pids.txt']"
      next
    end

    CSV.foreach(args[:arg1], encoding: "ISO8859-1") do |row|
      pid = row[0]
      begin
        record = TuftsBase.find(pid, cast: true)
      rescue ActiveFedora::ObjectNotFoundError
        puts "ERROR Could not locate object: #{pid}"
        next
      end
      if record.kind_of?(Array)
        puts "ERROR Multiple results for: #{pid}"
        next
      end

      begin
        published_object = TuftsBase.find(pid, cast: true)
        draft_pid = published_object.pid.sub('tufts','draft')
#        Job::Revert.new('uuid', 'record_id' => published_object.pid, 'batch_id' => 2).perform
        RevertService.new(published_object, 1).run
        #batch = BatchRevert.new(pids: [published_object.pid])
        #BatchRunnerService.new(batch).run
        draft_object = TuftsBase.find(draft_pid, cast: true)
        draft_object.publishing = true
        draft_object.save
        draft_object.publishing = false
        puts "Draft Created #{draft_object.pid}"
      rescue Rubydora::FedoraInvalidRequest => fir
        puts "Try to fix checksum here"
        FedoraObjectCopyService.new(published_object.class, from: published_object.pid, to: draft_pid, object: published_object).clean_completely
        draft_object = TuftsBase.find(draft_pid, cast: true)
        draft_object.update_index
        puts "Draft Created #{draft_pid}"
      rescue => exception
        puts "ERROR There was an error doing the conversion for: #{pid}"
        puts exception.message
        puts exception.backtrace
        puts exception.class
        next
      end
    end 
  end


end
