require 'json'
require 'net/http'
require 'openssl'

DEFAULT_STUFF = %w(boxen dnsmasq gcc git homebrew hub inifile nginx nodejs repository ruby stdlib sudo puppetlabs-inifile puppetlabs-stdlib)

def get(url)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Get.new(uri.request_uri)

  http.request(request)
end

# shamelessly stolen from puppet librarian
def api_call(path)
  url = "https://api.github.com#{path}"
  url << "?access_token=#{ENV['GITHUB_API_TOKEN']}" if ENV['GITHUB_API_TOKEN']
  resp = get(url)
  if resp.code.to_i != 200
    nil
  else
    data = resp.body
    JSON.parse(data)
  end
end

def guess_deps_from_readme(name)
  readme = get("https://raw.github.com/boxen/puppet-#{name}/master/README.md").body
  probably_in_dependencies = false
  deps = []
  readme.each_line do |line|
    if line == "## Required Puppet Modules\n"
      probably_in_dependencies = true
    elsif line[0..1] == "##"
      probably_in_dependencies = false
    elsif probably_in_dependencies && line[0] == '*'
      maybe_a_dependency = line.gsub(/\*/, '').gsub(/`/, '').gsub(/\s/, '')
      deps << maybe_a_dependency
    end
  end
  deps
end
result = []
deps = []
ARGV.each do |name|
  deps << name
  deps += guess_deps_from_readme(name)
end
deps = deps.compact.uniq
deps -= DEFAULT_STUFF
deps.each do |name|
  json = api_call("/repos/boxen/puppet-#{name}/tags")
  if json
    result << %Q{github "#{name}", "#{json[0]['name']}"}
  else
    puts "couldn't figure out tags for #{name}"
  end
end
result.sort.each { |result| puts result }
