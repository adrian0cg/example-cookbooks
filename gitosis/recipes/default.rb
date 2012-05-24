package "git-core"
package "gitosis"

#user "git" do
#  comment "Gitosis/Git user"
#  gid "users"
#  home "/srv/gitosis/"
#end

#directory "/srv/gitosis" do
#  action :create
#  owner "git"
#  group "users"
#end

execute "ensure correct permissions for gitosis" do
  command "chown -R gitosis /srv/gitosis"
end
