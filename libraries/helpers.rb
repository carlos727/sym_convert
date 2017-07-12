require 'net/smtp'
require 'net/http'
require 'json'

#
# Define general functions and methods
#
module Tool
  module_function

  def unindent(string)
    first = string[/\A\s*/]
    string.gsub /^#{first}/, ''
  end

  def send_email(to, mailtext)
    smtp = Net::SMTP.new('smtp.office365.com', 587)
    smtp.enable_starttls_auto
    smtp.start('smtp.office365.com', 'barcoder@redsis.com', 'Orion2015', :login)
    smtp.send_message(mailtext, 'barcoder@redsis.com', to)
    smtp.finish
  end

  def simple_email(to, subject, message)
    message = <<-MESSAGE
      From: Chef Reporter <barcoder@redsis.com>
      To: <#{to}>
      Subject: #{subject}

      #{message}
    MESSAGE

    mailtext = unindent message

    send_email to, mailtext
  end

  def attached_email(to, subject, message)
    filename = "C:\\chef\\log-#{Chef.run_context.node.name}"
    encodedcontent = [File.read(filename)].pack("m") # Read a file and encode it into base64 format
    marker = 'AUNIQUEMARKER'

    header = <<-HEADER
      From: Chef Reporter <barcoder@redsis.com>
      To: <#{to}>
      Subject: #{subject}
      MIME-Version: 1.0
      Content-Type: multipart/mixed; boundary=#{marker}
      --#{marker}
    HEADER

    body = <<-BODY
      Content-Type: text/plain
      Content-Transfer-Encoding:8bit

      #{message}
      --#{marker}
    BODY

    attached = <<-ATTACHED
      Content-Type: multipart/mixed; name=\"#{filename}\"
      Content-Transfer-Encoding:base64
      Content-Disposition: attachment; filename="#{filename}"

      #{encodedcontent}
      --#{marker}--
    ATTACHED

    mailtext = unindent header + body + attached

    send_email to, mailtext
  end

end

#
# Define functions and methods related to an Url
#
module Url
  module_function

  def is_reachable?(url)
    require 'mechanize'

    sw = true
    agent = Mechanize.new
    agent.user_agent_alias = 'Windows Chrome'
    agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    tries = 3
    cont = 0

    begin
    	agent.read_timeout = 5 #set the agent time out
    	page = agent.get(url)
  	rescue
      cont += 1
      unless (tries -= 1).zero?
        Chef::Log.warn("Verifying if url #{url} is reachable (#{cont}/3) failed, try again in 1 minutes...")
        agent.shutdown
        agent = Mechanize.new { |agent| agent.user_agent_alias = 'Windows Chrome'}
        agent.request_headers
        sleep(60)
        retry
      else
        Chef::Log.error("The url #{url} isn't available.")
        sw = false
      end
    else
      sw = true
    ensure
      agent.history.pop()   #delete this request in the history
    end

    return sw
  end

  def fetch(url)
    resp = Net::HTTP.get_response(URI.parse(url))
    data = resp.body
    return JSON.parse(data)
  end

end

Chef::Recipe.send(:include, Tool)
Chef::Recipe.send(:include, Url)
