service "pound" do
  supports :restart => true, :status => true
  action :nothing
end