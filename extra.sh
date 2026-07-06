sudo apt install buildah
# Add user to subuid/subgid files (requires root)
sudo usermod --add-subuids 100000-165535 viswar
sudo usermod --add-subgids 100000-165535 viswar
# Or manually edit files
echo "viswar:100000:65536" | sudo tee -a /etc/subuid
echo "viswar:100000:65536" | sudo tee -a /etc/subgid