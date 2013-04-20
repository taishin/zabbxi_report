# coding: utf-8

require 'thinreports'
require 'open-uri'
require 'rubygems'
require 'zbxapi'
require 'pp'

ZABBIX_SERVER = "10.1.1.1"
ZABBIX_LOGINID = "Admin"
ZABBIX_PASSWORD = "zabbix"
ZABBIX_HOSTGROUP = "Linux Servers"
ZABBIX_API_URL = "http://#{ZABBIX_SERVER}/zabbix/api_jsonrpc.php"
ZABBIX_GRAPH_URL = "http://#{ZABBIX_SERVER}/zabbix/chart2.php?&graphid="

START_MONTH = "04"
START_DAY = "12"
DAYS = 7

CUSTOMER = "株式会社 ・・・"


period = DAYS * 3600 * 24
stime = "2013#{START_MONTH}#{START_DAY}000000"

start_day = "2013年#{START_MONTH}月#{START_DAY}日"

zbxapi = ZabbixAPI.new(ZABBIX_API_URL)
zbxapi.login(ZABBIX_LOGINID, ZABBIX_PASSWORD)

hostgroup_id = zbxapi.hostgroup.get(
	"filter" => {
		"name" => ZABBIX_HOSTGROUP
	}
)[0]['groupid']


host_array =  zbxapi.host.get(
  "output" => "extend",
  "selectGraphs" => "extend",
  "selectInventory" => "true",
  "selectInterfaces" => "extend",
  "groupids" => hostgroup_id 
)

ThinReports::Report.generate_file("zabbix_report_#{stime}.pdf") do
  use_layout 'zabbix_report', :default => true
  use_layout 'zabbix_cover', :id => :cover

  start_new_page :layout => :cover
  page.item(:customer).value(CUSTOMER)
  page.item(:date).value(start_day)

  events.on :page_create do |e|
    # Set page-number.
    e.page.item(:page).value(e.page.no)
  end

  host_array.each { |host|
    array = Hash.new

    host["graphs"].each { |graph|
      array[graph["name"]] = graph["graphid"]
    }

    i = 0
    array.sort.each do |key, value|
      y = i % 8
      if y == 0 then
  		  start_new_page
  		  page.item(:hostname).value(host["name"])
  		  page.item(:os).value(host['inventory']['os'])
  		  host['interfaces'].each do |int|
          page.item(:ip).value(int[1]['ip'])
        end
      end
 	    page.item(:"n#{y}").value(key)
		  page.item(:"g#{y}").src(open("#{ZABBIX_GRAPH_URL}#{value}&period=#{period}&stime=#{stime}&width=450&height=100"))
		  i += 1
    end
  }
end
puts 'Done!'
