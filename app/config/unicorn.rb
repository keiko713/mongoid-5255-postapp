worker_processes 1
timeout 15
preload_app true

after_fork do |server, worker|
  Mongoid::Clients.clients.each do |name, client|
    client.close
    client.reconnect
  end
end

before_fork do |server, worker|
  Mongoid.disconnect_clients
end