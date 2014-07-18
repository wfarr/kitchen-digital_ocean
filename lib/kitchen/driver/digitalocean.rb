# -*- encoding: utf-8 -*-
#
# Author:: Greg Fitzgerald (<greg@gregf.org>)
#
# Copyright (C) 2013, Greg Fitzgerald
# Copyright (C) 2014, Will Farrington
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'rest_client'
require 'json'
require 'kitchen'
require 'etc'
require 'socket'

module Kitchen
  module Driver
    # Digital Ocean driver for Kitchen.
    #
    # @author Greg Fitzgerald <greg@gregf.org>
    class Digitalocean < Kitchen::Driver::SSHBase
      IMAGES = {
        "ubuntu-12.04": "ubuntu-12-04-x64",
        "ubuntu-14.04": "ubuntu-14-04-x64",
      }

      default_config :username, 'root'
      default_config :port, '22'

      default_config :private_networking, true

      default_config :region, 'nyc2'
      default_config :size, '2gb'

      default_config :image do |driver|
        driver.default_image
      end

      default_config :server_name do |driver|
        driver.default_name
      end

      default_config :digitalocean_api_token do
        ENV['DIGITALOCEAN_API_TOKEN']
      end

      default_config :ssh_keys do
        ENV['DIGITALOCEAN_SSH_KEYS']
      end

      required_config :digitalocean_api_token
      required_config :ssh_key_ids

      def create(state)
        droplet = create_droplet
        state[:server_id] = droplet.id

        info("Digital Ocean instance <#{state[:server_id]}> created.")

        server.wait_for { print '.'; ready? } ; print '(server ready)'
        state[:hostname] = server.public_ip_address

        wait_for_sshd(state[:hostname]) ; print "(ssh ready)\n"
        debug("digitalocean:create #{state[:hostname]}")
      rescue  RestClient::Exception => e
        raise ActionFailed, e.message
      end

      def destroy(state)
        return if state[:server_id].nil?

        if get_droplet(state[:server_id])
          destroy_droplet state[:server_id]
        end

        info("Digital Ocean instance <#{state[:server_id]}> destroyed.")

        state.delete(:server_id)
        state.delete(:hostname)
      end

      def default_image
        IMAGES.fetch(instance.platform.name) { 'ubuntu-14-04-x64' }
      end

      def default_name
        # Generate what should be a unique server name
        rand_str = Array.new(8) { rand(36).to_s(36) }.join
        "#{instance.name}-"\
        "#{Etc.getlogin.gsub('_', '-')}-"\
        "#{rand_str}-"\
        "#{Socket.gethostname}"
      end

      private

      def get_droplet(id)
        api_request :get, "droplets/#{id}")['droplet']
      rescue  RestClient::Exception => e
        nil
      end

      def create_droplet
        debug_droplet_config

        api_request :post, 'droplets', {
          name: config[:server_name],
          region: config[:region],
          size: config[:size],
          image: config[:image],
          ssh_keys: config[:ssh_keys].split(','),
        }
      end

      def destroy_droplet(id)
        api_request :delete, "droplets/#{id}"
      end

      def debug_droplet_config
        debug("digitalocean_api_token #{config[:digitalocean_api_token]}")
        debug("digitalocean:name #{config[:server_name]}")
        debug("digitalocean:image_id #{config[:image_id]}")
        debug("digitalocean:flavor_id #{config[:flavor_id]}")
        debug("digitalocean:region_id #{config[:region_id]}")
        debug("digitalocean:ssh_key_ids #{config[:ssh_key_ids]}")
        debug("digitalocean:private_networking #{config[:private_networking]}")
      end

      def api_request(method, url, content=nil)
        url = "https://api.digitalocean.com/v2/#{url}" unless url =~ /^http/
        headers = {'Authorization' => "Bearer #{ENV['DO_API_TOKEN']}"}
        if %w(get head delete).include? method.to_s
          res = RestClient.send(method.to_sym, url, headers)
          json = JSON.parse(res) unless res.empty?

          if json['links'] && json['links']['pages'] && json['links']['pages']['next']
            json.deep_merge!(api_request(method, json['links']['pages']['next']))
          else
            json
          end
        elsif %w(post put).include? method.to_s
          begin
            JSON.parse(RestClient.send(method.to_sym, url, content, headers.merge(:content_type => 'application/json')))
          rescue RestClient::Exception => rce
            raise rce
          end
        else
          raise "What kind of HTTP method actually is #{method}"
        end
      end

    end
  end
end

# vim: ai et ts=2 sts=2 sw=2 ft=ruby
