require 'csv'
require 'active_fedora'

namespace :tufts_data do
  task :generate_pdf_thumbs, [:arg1] => :environment do |t, args|
    if args[:arg1].nil?
      puts "YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!"
      next
    end

    CSV.foreach(args[:arg1], encoding: "ISO8859-1") do |row|
      pid = row[0]
      begin
        GC.start(full_mark: true, immediate_sweep: true)
        puts "Processing #{pid}"
        record = TuftsBase.find(pid, cast: true)
        record.create_thumb_backport
        record.save!  
      rescue Magick::ImageMagickError
        puts "ERROR converting: #{pid}"
        next
      rescue ActiveFedora::ObjectNotFoundError
        puts "ERROR Could not locate object: #{pid}"
        next
      end

      if record.kind_of?(Array)
        puts "ERROR Multiple results for: #{pid}"
        next
      end
      #puts "#{pid}"
      #PublishService.new(record).run
    end
  end

  task :publish_existing_objects, [:arg1] => :environment do |t, args|
    if args[:arg1].nil?
      puts "YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!"
      next
    end

    CSV.foreach(args[:arg1], encoding: "ISO8859-1") do |row|
      pid = row[0]
      begin
        # assumes removal of oai reference record and sample pids
        # and template objects
        record = TuftsBase.find(pid)
        published_pid = pid.gsub("draft:","tufts:")
      #  record.save!  
        # if the object is not already published, publish it.
        next unless ActiveFedora::Base.exists?(published_pid)
      rescue ActiveFedora::ObjectNotFoundError
        puts "ERROR Could not locate object: #{pid}"
        next
      end

      if record.kind_of?(Array)
        puts "ERROR Multiple results for: #{pid}"
        next
      end
      puts "#{pid}"
      PublishService.new(record).run
    end
  end

  task :dca_date_normalization, [:arg1] => :environment do |t, args|
    if args[:arg1].nil?
      puts "YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!"
      next
    end

    CSV.foreach(args[:arg1], encoding: "ISO8859-1") do |row|
      pid = row[0]
      begin
        record = TuftsBase.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
        puts "ERROR Could not locate object: #{pid}"
        next
      end
      if record.kind_of?(Array)
        puts "ERROR Multiple results for: #{pid}"
        next
      end 
      puts "#{pid}"
      record.date= record.date_created unless record.date_created.empty?
      record.date_created= []
      record.save!
    end 
  end

  task :date_detail_normalization, [:arg1] => :environment do |t, args|
    if args[:arg1].nil?
      puts "YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!"
      next
    end

    CSV.foreach(args[:arg1], encoding: "ISO8859-1") do |row|
      pid = row[0]
      begin
        record = TuftsBase.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
        puts "ERROR Could not locate object: #{pid}"
        next
      end
      if record.kind_of?(Array)
        puts "ERROR Multiple results for: #{pid}"
        next
      end 
      puts "#{pid}"
      record.date= record.date_deprecated unless record.date_deprecated.empty?
      record.isPartOf= record.isPartOf_deprecated unless record.isPartOf_deprecated.empty?
      record.isPartOf_deprecated= nil unless record.isPartOf_deprecated.empty?
      record.date_deprecated= nil unless record.date_deprecated.empty?
      record.save!
    end 
  end

  task :tisch_data_migration, [:arg1] => :environment do |t, args|
    if args[:arg1].nil?
      puts "YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!"
      next
    end

    CSV.foreach(args[:arg1], encoding: "ISO8859-1") do |row|
      pid = row[0]
      begin
        aah_record = TuftsBase.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
        puts "ERROR Could not locate object: #{pid}"
        next
      end
      if aah_record.kind_of?(Array)
        puts "ERROR Multiple results for: #{pid}"
        next
      end

      begin
        ds_opts = {:label => 'Administrative Metadata'}
        new_dca_admin = aah_record.create_datastream DcaAdmin, 'DCA-ADMIN', ds_opts
        new_dca_admin.ng_xml = DcaAdmin.xml_template
        #new_dca_admin.steward = "dca"
        old_dca_admin = aah_record.datastreams['DCA-ADMIN']
        new_dca_admin.template_name = old_dca_admin.template_name unless old_dca_admin.template_name.empty?
        new_dca_admin.steward = old_dca_admin.steward unless old_dca_admin.steward.empty?
        new_dca_admin.name = old_dca_admin.steward unless old_dca_admin.name.empty?
        new_dca_admin.comment = old_dca_admin.comment unless old_dca_admin.comment.empty?
        new_dca_admin.retentionPeriod = old_dca_admin.retentionPeriod unless old_dca_admin.retentionPeriod.empty?
        new_dca_admin.displays = old_dca_admin.displays unless old_dca_admin.displays.empty?
        new_dca_admin.embargo = old_dca_admin.embargo unless old_dca_admin.embargo.empty?
        new_dca_admin.status = old_dca_admin.status unless old_dca_admin.status.empty?
        new_dca_admin.startDate = old_dca_admin.startDate unless old_dca_admin.startDate.empty?
        new_dca_admin.expDate = old_dca_admin.expDate unless old_dca_admin.expDate.empty?
        new_dca_admin.qrStatus = old_dca_admin.qrStatus unless old_dca_admin.qrStatus.empty?
        new_dca_admin.rejectionReason = old_dca_admin.rejectionReason unless old_dca_admin.rejectionReason.empty?
        new_dca_admin.note = old_dca_admin.note unless old_dca_admin.note.empty?
        new_dca_admin.createdby = old_dca_admin.createdby unless old_dca_admin.createdby.empty?
        new_dca_admin.creatordept = old_dca_admin.creatordept unless old_dca_admin.creatordept.empty?
        new_dca_admin.batch_id = old_dca_admin.batch_id unless old_dca_admin.batch_id.empty?
        new_dca_admin.published_at = old_dca_admin.published_at[0] unless old_dca_admin.published_at.empty?
        new_dca_admin.edited_at = old_dca_admin.edited_at[0] unless old_dca_admin.edited_at.empty?

        if aah_record.datastreams['DCA-ADMIN'].nil?
          aah_record.add_datastream new_dca_admin
        else
          aah_record.datastreams['DCA-ADMIN'] = new_dca_admin
        end

       aah_record.save!

      rescue => exception
        puts "ERROR There was an error doing the conversion for: #{pid}"
        puts exception.backtrace
        next
      end
    end 
  end
end
