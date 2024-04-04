# Use systemd for managing NVIDIA driver suspend in drivers ====>>> PRIOR to version 470 <<<=====
# https://download.nvidia.com/XFree86/Linux-x86_64/450.66/README/powermanagement.html
# https://forums.developer.nvidia.com/t/unable-to-set-nvidia-kernel-module-parameters/161306
# Please note: In Fedora Linux you may need to just install the xorg-x11-drv-nvidia-power pakage
# as sugested by @goombah88 in the comments below.

TMP_PATH=/var/tmp
TMPL_PATH=/usr/share/doc/nvidia-driver-460/

echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1 NVreg_TemporaryFilePath=${TMP_PATH}" | sudo tee /etc/modprobe.d/nvidia-power-management.conf

sudo install --mode 644 "${TMPL_PATH}/nvidia-suspend.service" /etc/systemd/system
sudo install --mode 644 "${TMPL_PATH}/nvidia-hibernate.service" /etc/systemd/system
sudo install --mode 644 "${TMPL_PATH}/nvidia-resume.service" /etc/systemd/system
sudo install "${TMPL_PATH}/nvidia" /lib/systemd/system-sleep
sudo install "${TMPL_PATH}/nvidia-sleep.sh" /usr/bin

sudo systemctl enable nvidia-suspend.service
sudo systemctl enable nvidia-hibernate.service
sudo systemctl enable nvidia-resume.service
