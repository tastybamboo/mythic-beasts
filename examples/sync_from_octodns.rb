#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "mythic_beasts"
require "yaml"

# Configure the Mythic Beasts client
MythicBeasts.configure do |config|
  config.api_key = ENV["MYTHIC_BEASTS_API_KEY"]
  config.api_secret = ENV["MYTHIC_BEASTS_API_SECRET"]
end

client = MythicBeasts.client
zone_name = ARGV.find { |arg| !arg.start_with?("--") } || "neurobetter.org"

puts "=== OctoDNS to Mythic Beasts DNS Sync ==="
puts "Zone: #{zone_name}"
puts

# Load the OctoDNS zone file
zone_file = File.join(__dir__, "../../octodns/zones/#{zone_name}.yaml")
unless File.exist?(zone_file)
  puts "Zone file not found: #{zone_file}"
  exit 1
end

zone_data = YAML.load_file(zone_file)
puts "Loaded zone file: #{zone_file}"
puts

# Get current DNS records from Mythic Beasts
puts "Fetching current DNS records from Mythic Beasts..."
current_records_response = client.dns.records(zone_name)
current_records = current_records_response["records"] || []
puts "Found #{current_records.length} current records"
puts

# Group current records by hostname to detect conflicts
current_by_host = current_records.group_by { |r| r["host"] }
current_types_by_host = current_by_host.transform_values do |records|
  records.map { |r| r["type"] }.uniq.sort
end

# Normalize current records for comparison
# Convert API format to our internal format
normalized_current = current_records.map do |r|
  rec = {
    host: r["host"],
    type: r["type"],
    ttl: r["ttl"],
    data: r["data"]
  }
  rec[:mx_priority] = r["mx_priority"] if r["mx_priority"]
  rec
end

# Convert OctoDNS format to Mythic Beasts format
def convert_octodns_to_mythic(hostname, record_data, default_ttl = 300)
  records = []

  # Handle array of record sets
  record_data.each do |record_set|
    type = record_set["type"]
    ttl = record_set["ttl"] || default_ttl

    case type
    when "A", "AAAA", "TXT"
      # These can have multiple values
      values = record_set["values"] || [record_set["value"]]
      values.each do |value|
        records << {
          host: hostname,
          type: type,
          ttl: ttl,
          data: value
        }
      end

    when "CNAME"
      # CNAME has a single value
      records << {
        host: hostname,
        type: type,
        ttl: ttl,
        data: record_set["value"]
      }

    when "MX"
      # MX records have priority and value
      values = record_set["values"] || [record_set]
      values.each do |mx|
        records << {
          host: hostname,
          type: type,
          ttl: ttl,
          data: mx["value"],
          mx_priority: mx["priority"]
        }
      end

    when "CAA"
      # CAA records have flags, tag, and value
      values = record_set["values"] || [record_set]
      values.each do |caa|
        records << {
          host: hostname,
          type: type,
          ttl: ttl,
          data: "#{caa["flags"]} #{caa["tag"]} \"#{caa["value"]}\""
        }
      end

    else
      puts "Unsupported record type: #{type} for #{hostname}"
    end
  end

  records
end

# Build records to sync
records_to_sync = []
zone_data.each do |hostname, record_data|
  # Convert empty string to @ for root domain
  host = hostname.empty? ? "@" : hostname

  records = convert_octodns_to_mythic(host, record_data)
  records_to_sync.concat(records)
end

puts "=== Records to Sync (#{records_to_sync.length} total) ==="
records_to_sync.group_by { |r| r[:host] }.each do |host, records|
  puts "\n#{(host == "@") ? "(root)" : host}:"
  records.group_by { |r| r[:type] }.each do |type, type_records|
    puts "  #{type}:"
    type_records.each do |record|
      data = (record[:data].length > 60) ? "#{record[:data][0..60]}..." : record[:data]
      puts "    - #{data} (TTL: #{record[:ttl]})"
    end
  end
end

# Detect conflicts (CNAME cannot coexist with other record types)
conflicts = []
records_to_sync.group_by { |r| r[:host] }.each do |host, records|
  new_types = records.map { |r| r[:type] }.uniq.sort
  current_types = current_types_by_host[host] || []

  # Check for CNAME conflicts
  has_cname_now = current_types.include?("CNAME")
  will_have_cname = new_types.include?("CNAME")
  has_other_now = (current_types - ["CNAME"]).any?
  will_have_other = (new_types - ["CNAME"]).any?

  # Conflict: CNAME exists and we're adding other types
  if has_cname_now && will_have_other
    conflicts << {
      host: host,
      action: "delete_cname_add_records",
      current: current_types,
      new: new_types,
      message: "Will DELETE existing CNAME and ADD #{(new_types - ["CNAME"]).join(", ")}"
    }
  end

  # Conflict: Other types exist and we're adding CNAME
  if has_other_now && will_have_cname
    conflicts << {
      host: host,
      action: "delete_records_add_cname",
      current: current_types,
      new: new_types,
      message: "Will DELETE existing #{(current_types - ["CNAME"]).join(", ")} and ADD CNAME"
    }
  end
end

# Display conflicts if any
if conflicts.any?
  puts "\n" + "=" * 50
  puts "CONFLICTS DETECTED (#{conflicts.length})"
  puts "=" * 50
  conflicts.each do |conflict|
    puts "\nHost: #{conflict[:host]}"
    puts "  Current: #{conflict[:current].join(", ")}"
    puts "  New:     #{conflict[:new].join(", ")}"
    puts "  Action:  #{conflict[:message]}"
  end
  puts "\n" + "=" * 50
end

# Determine which host/type combinations have changes
# We need to compare sets of records for each host/type combination
host_types_to_sync = Set.new
changed_record_count = 0
unchanged_count = 0

records_to_sync.group_by { |r| [r[:host], r[:type]] }.each do |(host, type), new_records|
  # Get current records for this host/type
  current_for_host_type = normalized_current.select { |r| r[:host] == host && r[:type] == type }

  # Convert to sets for comparison (excluding host/type since they're the grouping key)
  new_set = new_records.map { |r| r.slice(:ttl, :data, :mx_priority).compact }.to_set
  current_set = current_for_host_type.map { |r| r.slice(:ttl, :data, :mx_priority).compact }.to_set

  if new_set != current_set
    # This host/type combination has changes
    host_types_to_sync.add([host, type])

    # Count how many individual records changed
    new_records.each do |new_rec|
      existing = current_for_host_type.find do |curr|
        curr[:ttl] == new_rec[:ttl] &&
          curr[:data] == new_rec[:data] &&
          curr[:mx_priority] == new_rec[:mx_priority]
      end
      if existing
        unchanged_count += 1
      else
        changed_record_count += 1
      end
    end
  else
    # All records in this host/type are unchanged
    unchanged_count += new_records.length
  end
end

if host_types_to_sync.empty? && conflicts.empty?
  puts "\n" + "=" * 50
  puts "All records are already up to date!"
  puts "=" * 50
  puts "\n#{unchanged_count} record(s) match what's already in DNS."
  exit 0
end

if unchanged_count > 0 || changed_record_count > 0
  puts "\n" + "=" * 50
  puts "Summary"
  puts "=" * 50
  puts "  Unchanged: #{unchanged_count} record(s)"
  puts "  Changed:   #{changed_record_count} record(s)"
  puts "  Host/Types to update: #{host_types_to_sync.size}"
  if conflicts.any?
    puts "  Conflicts: #{conflicts.length} host(s)"
  end
end

puts "\n" + "=" * 50
puts "Ready to sync #{changed_record_count} changed record(s) in #{host_types_to_sync.size} host/type combination(s)"
if unchanged_count > 0
  puts "(#{unchanged_count} unchanged record(s) will be included in updates)"
end
if conflicts.any?
  puts "#{conflicts.length} conflict(s) will be resolved by deleting old records first"
end
puts "=" * 50

if ARGV.include?("--dry-run")
  puts "\nDry run complete. Use --apply to sync changes."
  exit 0
end

unless ARGV.include?("--apply")
  puts "\nThis is a dry run. Add --apply to actually sync the records."
  puts "   Example: bundle exec ruby #{__FILE__} --apply"
  puts "   With verification: bundle exec ruby #{__FILE__} --apply --verify"
  exit 0
end

# Ask for confirmation if there are conflicts (unless --yes flag is provided)
if conflicts.any? && !ARGV.include?("--yes")
  puts "\nConflicts will result in records being DELETED before new ones are added."
  puts "   This could cause temporary DNS downtime for the affected hosts."
  print "\nDo you want to proceed? (yes/no): "

  response = $stdin.gets.chomp.downcase
  unless response == "yes" || response == "y"
    puts "\nSync cancelled by user."
    exit 0
  end
  puts
end

# Apply the changes
puts "\nSyncing records to Mythic Beasts DNS..."

begin
  # Track which hosts we've already handled conflicts for
  resolved_conflicts = Set.new

  # Group records by host and type for efficient updates
  records_to_sync.group_by { |r| [r[:host], r[:type]] }.each do |(host, type), records|
    # Skip if this host/type doesn't need updating and has no conflict
    conflict = conflicts.find { |c| c[:host] == host }
    next unless host_types_to_sync.include?([host, type]) || conflict

    if conflict && !resolved_conflicts.include?(host)
      puts "Resolving conflict for #{host}..."

      # Delete all existing records for this host
      current_types = current_types_by_host[host] || []
      current_types.each do |existing_type|
        # Only delete if it's different from what we're adding, or if it's a CNAME conflict
        if existing_type == "CNAME" || (conflict[:action] == "delete_records_add_cname" && existing_type != "CNAME")
          puts "  Deleting #{host}/#{existing_type}..."
          begin
            client.dns.delete_records(zone_name, host: host, type: existing_type)
            puts "    Deleted"
          rescue MythicBeasts::Error => e
            # Ignore 404 errors (record already doesn't exist)
            unless e.message.include?("404")
              raise
            end
            puts "    Already deleted or doesn't exist"
          end
        end
      end

      resolved_conflicts.add(host)
      puts
    end

    puts "Updating #{host}/#{type}..."

    # Prepare records for API (remove :host and :type as they're in the URL)
    api_records = records.map do |r|
      record = {
        ttl: r[:ttl],
        data: r[:data]
      }
      # Add mx_priority for MX records
      record[:mx_priority] = r[:mx_priority] if r[:mx_priority]
      record
    end

    # Use update_records to replace existing records
    client.dns.update_records(
      zone_name,
      api_records,
      host: host,
      type: type
    )

    puts "  Updated #{records.length} record(s)"
  end

  puts "\n" + "=" * 50
  puts "DNS sync complete!"
  puts "=" * 50
  puts "\nChanges may take a few minutes to propagate."

  # Run verification if --verify flag is passed
  if ARGV.include?("--verify")
    puts "\n" + "=" * 50
    puts "Running email authentication verification..."
    puts "=" * 50
    puts

    # Wait a moment for DNS to propagate
    sleep 2

    # Run the verification script
    verification_script = File.join(__dir__, "verify_email_auth.rb")
    system("bundle exec ruby #{verification_script} #{zone_name.chomp(".")}")
  end
rescue MythicBeasts::Error => e
  puts "\nAPI Error: #{e.message}"
  exit 1
rescue => e
  puts "\nError: #{e.class}: #{e.message}"
  puts e.backtrace.first(5)
  exit 1
end
