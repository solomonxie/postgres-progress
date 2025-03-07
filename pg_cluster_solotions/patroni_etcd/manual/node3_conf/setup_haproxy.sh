# ==== DON'T EXECUTE THIS SCRIPT DIRECTLY ====

# Install HAProxy
sudo apt install haproxy -y
/sbin/haproxy -v
sudo systemctl enable haproxy
sudo vim /etc/haproxy/haproxy.cfg
# >>> put below content >>>
# ...
sudo systemctl restart haproxy
sudo systemctl status haproxy
