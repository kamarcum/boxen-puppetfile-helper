require 'json'
require 'net/http'
require 'openssl'

# shamelessly stolen from puppet librarian
def api_call(path)
  url = "https://api.github.com#{path}"
  url << "?access_token=#{ENV['GITHUB_API_TOKEN']}" if ENV['GITHUB_API_TOKEN']
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Get.new(uri.request_uri)

  resp = http.request(request)
  if resp.code.to_i != 200
    nil
  else
    data = resp.body
    JSON.parse(data)
  end
end
result = []
ARGV.each do |name|
  json = api_call("/repos/boxen/puppet-#{name}/tags")
  result << %Q{github "#{name}", "#{json[0]['name']}"}
end
result.sort.each { |result| puts result }
