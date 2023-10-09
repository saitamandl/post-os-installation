#!/bin/bash

tmp_state_file=$HOME/_$USER-setup.state
is_run_by_state=false
if [ $# -eq 1 ]; then
   PHASE=$1
elif [ -e $tmp_state_file ] && [ ! -z $(cat $tmp_state_file) ]; then
   PHASE=$(cat $tmp_state_file)
else
    PHASE=0
fi

create_tmp_state_file(){
    if [ -e $tmp_state_file ]; then
        (( PHASE = PHASE + 1 ))
        echo $PHASE > $tmp_state_file
    else
        touch $tmp_state_file
        (( PHASE = PHASE + 1 ))
        echo $PHASE > $tmp_state_file
    fi
}
update_upgarde() {
    echo "Starting post Fedora install setup"
    echo "Update & upgrade..."
    sudo dnf update -y
    sudo dnf upgrade --refresh
    sudo dnf install -y dnf-plugin-system-upgrade
    sudo dnf system-upgrade -y download
    echo "Installing post set upgrade. Rebooting..."
    sudo dnf system-upgrade reboot
}

change_hostname() {
    echo "Hostname: "
    read usr_inp_hostname
    if [ $(hostname) ! = $usr_inp_hostname ]; then
        sudo hostnamectl set-hostname "$usr_inp_hostname"
        create_tmp_state_file
        sudo reboot
    fi
}

speed_up_dnf() {
    is_dnf_speed_up=1 
    dnf_conf_file="/etc/dnf/dnf.conf"
    while read -r line; do
        if [[ $line = "# Added for speed" ]]; then
            is_dnf_speed_up=0
            break
        fi
    done < "$dnf_conf_file"

    # echo -e "Do you want to speed up dnf? \n\t0. no \n\t1. yes"
    # read is_dnf_speed_up
    if [ $is_dnf_speed_up -eq 1 ]; then
        echo '# Added for speed' | sudo tee -a /etc/dnf/dnf.conf
        echo 'fastestmirror=1' | sudo tee -a /etc/dnf/dnf.conf
        echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf
        echo 'defaultyes=True' | sudo tee -a /etc/dnf/dnf.conf
        echo 'keepcache=True' | sudo tee -a /etc/dnf/dnf.conf
        sudo dnf clean dbcache
        sudo dnf clean all
    fi
}

enable_gpg_signature_verification() {
    echo "Enabling GPG signature verification on installs..."
    sudo dnf install -y distribution-gpg-keys
    sudo rpmkeys --import /usr/share/distribution-gpg-keys/rpmfusion/RPM-GPG-KEY-rpmfusion-free-fedora-$(rpm -E %fedora)
    sudo dnf --setopt=localpkg_gpgcheck=1 install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
    echo "GPG signature verification on installs enabling!!! "
}

enable_rpm_free_nonfree() {
    echo "Enabling RPM fusion free and nonfree..."
    sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf groupupdate -y core
    echo "RPM fusion free and nonfree enabled!!!"
}

enable_flatpack() {
    echo "Enabling flatpack..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo "Flatpack is enabled!!!"
}

install_snap() {
    sudo dnf install -y snapd
}

install_codecs() {
    echo "Installing codecs..."
    sudo dnf groupupdate -y multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
    sudo dnf groupupdate -y sound-and-video
    echo "Codecs Installed!!!"
}

install_quality_of_life_apps(){
    echo "Installing apps to improve quality of life..."
    sudo dnf install -y gnome-tweak-tool
    sudo dnf install -y timeshift
    sudo dnf install -y wireguard-tools
    sudo dnf install -y neovim python3-neovim
    echo "Apps to improve quality of life installed!!!"
}

install_zsh(){
    sudo dnf install -y zsh
    #sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    #export ZSH="$HOME/.oh-my-zsh"
    #sudo lchsh $USER
}


install_nvidia_cuda(){
    echo -e "Do you want to installing NVIDIA drivers with cuda? \n\t0. no \n\t1. yes"
    read is_install_nvidia_driver
    if [ $is_install_nvidia_driver -eq 1 ]
    then
        echo "Installing NVIDIA drivers with cuda..."
        sudo dnf update -y
        sudo dnf install -y akmod-nvidia
        sudo dnf install -y xorg-x11-drv-nvidia-cuda
        echo "NVIDIA drivers with cuda installed. Rebooting..."
        create_tmp_state_file
        sudo reboot
    fi
}

enable_gnome_extension(){
    echo -e "Do you want to enable gnome extension? \n\t0. no \n\t1. yes"
    read is_enable_gnome_extension
    if [ $is_enable_gnome_extension -eq 1 ]
    then
        echo "Enabling gnome extension..."
        dnf install -y chrome-gnome-shell gnome-extensions-app
        echo "Gnome extension enabled!!!"
    fi
}

install_brave_browser(){
    echo -e "Do you want to Install Brave? \n\t0. no \n\t1. yes"
    read is_enable_gnome_extension
    if [ $is_enable_gnome_extension -eq 1 ]
    then
        echo "Installing Brave browser..."
        sudo dnf install -y dnf-plugins-core
        sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
        sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
        sudo dnf install -y brave-browser
        echo "Brave browser installed!!!"
    fi
}

install_docker(){
    echo "Installing docker..."
    sudo dnf -y install dnf-plugins-core
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo "Docker installed!!!"
}


install_wine(){
    echo "Installing wine..."
    sudo dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/37/winehq.repo
    sudo dnf install -y winehq-stable
    echo "Wine installed!!!"
}

download_intellij(){
    echo -e "Do you want to install Intellij? \n\t0. no \n\t1. yes"
    read is_enable_gnome_extension
    if [ $is_enable_gnome_extension -eq 1 ]
    then
        echo "Installing Intellij..."
        cd $HOME/Downloads
        wget https://download.jetbrains.com/idea/ideaIC-2022.3.3.tar.gz
        tar -xf ideaIC-2022.3.3.tar.gz
        cd ..
        echo "Intellij installed!!!"
    fi
}

install_vscode(){
    echo -e "Do you want to install vscode? \n\t0. no \n\t1. yes"
    read is_enable_gnome_extension
    if [ $is_enable_gnome_extension -eq 1 ]
    then
        echo "Installing VScode..."
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
        dnf check-update
        sudo dnf -y install code
        echo "VScode installed!!!"
    fi
}

install_vscodium(){
    echo -e "Do you want to install VSCodium? \n\t0. no \n\t1. yes"
    read is_enable_gnome_extension
    if [ $is_enable_gnome_extension -eq 1 ]
    then
        echo "Installing VScodium..."
        sudo rpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
        printf "[gitlab.com_paulcarroty_vscodium_repo]\nname=download.vscodium.com\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h" | sudo tee -a /etc/yum.repos.d/vscodium.repo
        sudo dnf install -y codium
        echo "VScodium installed!!!"
    fi
}

exit_setup(){
    if [ -e $tmp_state_file ]; then
        rm $tmp_state_file
    fi
    echo "Setup Completed!!!"
    endloop=true
    exit
}

run_by_state() {
    echo -e "1. Update and upgrade after new/fresh install.
    \n 2. Change Hostname.
    \n 3. Speed up DNF by using the fastest server and parallel download.
    \n 4. Enable GPG signature verification.
    \n 5. Enable RPM fusion free and nonfree.
    \n 6. Enable Flatpack.
    \n 7. Install snap.
    \n 8. Install Codecs.
    \n 9. Install quality of life app (Gnome tweal tools, timeshift, wireguard)
    \n 10. Enable gnome extension.
    \n 11. Install Zsh.
    \n 12. Install docker.
    \n 13. Install wine.
    \n 14. Download Intellij.
    \n 15. Install VS Code/Codium.
    \n 16. Install Brave browser.
    \n 17. Install NVIDIA drivers with cuda.
    \n 18. Exit Setup.
    "
    read state
    PHASE=$state
    is_run_by_state=true
}

endloop=false
while [ ${endloop} = false ]; do
   case ${PHASE} in
        0) run_by_state ;;
        1) update_upgarde ;;
        2) change_hostname ;;
        3) speed_up_dnf ;;
        4) enable_gpg_signature_verification ;;
        5) enable_rpm_free_nonfree ;;
        6) enable_flatpack ;;
        7) install_snap ;;
        8) install_codecs ;;
        9) install_quality_of_life_apps ;;
        10) enable_gnome_extension ;;
        11)install_zsh ;;
        12) install_docker ;;
        13) install_wine ;;
        14) download_intellij ;;
        15) install_vscodium ;;
        16) install_brave_browser ;;
        17) install_nvidia_cuda ;;
        18) exit_setup ;;
        *) endloop=true; echo "Phase ${PHASE} not supported" ;;
    esac
    if [ ${is_run_by_state} = false ]; then
        (( PHASE = PHASE + 1 ))
    else
        is_run_by_state=false
    fi
done