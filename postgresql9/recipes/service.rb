service "postgresql" do
  action :nothing
  supports :restart => true, :start => true
end
