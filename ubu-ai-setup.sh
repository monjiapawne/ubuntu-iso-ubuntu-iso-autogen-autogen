#!/bin/bash

# === colours === #
BLUE="\e[34m"
YELLOW="\e[1;33m"
RED="\e[1;31m"
GREEN="\e[1;32m"
RESET="\e[0m"

ubuntu_ver_check() {
  echo -e "select an ubuntu version: \n----------\n22)     ubuntu 22\n24)     ubuntu 24\ncustom) provide custom ubuntu path\n"
  read -p "ubuntu version: " ubuntu_version
  while [[ $ubuntu_version != 22 && $ubuntu_version != 24 && $ubuntu_version != custom ]]; do
    echo "invalid version"
    echo "select an ubuntu version: 22,24"
    read -p "ubuntu version: " ubuntu_version
  done
  if [[ $ubuntu_version == 22 ]]; then
    ubu_link="https://releases.ubuntu.com/jammy/ubuntu-22.04.5-live-server-amd64.iso"
  elif [[ $ubuntu_version == 24 ]]; then
    ubu_link="https://releases.ubuntu.com/noble/ubuntu-24.04.2-live-server-amd64.iso"
  elif [[ "$ubuntu_version" == "custom" ]]; then
    while [[ ! -f "$ubu_link" ]]; do
      read -p "Provide path to .iso or type [find]: " ubu_link
      [[ "$ubu_link" == "find" ]] && find / -type f -name "*.iso" 2>/dev/null
    done
    read -p "cp or mv: " cp_or_mv
  fi
  iso=$(basename "$ubu_link")
}

userinput() {
  filename=nocloud/user-data
  echo -e "${GREEN} [i]${RESET} Verifying packages"
  sudo apt update -qq >/dev/null 2>&1
  command -v whois &>/dev/null || {
    sudo apt -qq install whois -y >/dev/null 2>&1
    command -v whois &>/dev/null && echo -e "${GREEN} [✓]${RESET} whois installed" || echo "${RED}[x]${RESET} whois package missing"
  }
  command -v xorriso &>/dev/null || {
    sudo apt -qq install xorriso -y >/dev/null 2>&1
    command -v xorriso &>/dev/null && echo -e "${GREEN} [✓]${RESET} xorriso installed" || echo "${RED}[x]${RESET} xorriso package missing"
  }
  read -p "hostname: " hostname
  read -p "username: " username
  read -p "password: " password
  command -v mkpasswd >/dev/null || sudo apt -y install whois; encryptedp=$(echo "$password" | mkpasswd --method=sha-512 --stdin)
}

if [ $EUID -eq 0 ]; then
  echo -e "${GREEN}<==== Ubuntu AutoInstall ISO Generator ====>${RESET}"
  userinput
  scriptloc=$(pwd)
  i=1
  while [ -d "/tmp/ubuautoscript_$i" ]; do
    i=$((i + 1))
  done
  mkdir "/tmp/ubuautoscript_$i"
  cd "/tmp/ubuautoscript_$i"
  ubuntu_ver_check
  
  if [[ "$ubuntu_version" == "custom" ]]; then
    if [[ "$cp_or_mv" == "mv" ]]; then
      mv "$ubu_link" "/tmp/ubuautoscript_$i"
      echo -e "${GREEN} [i]${RESET} moving ISO $ubu_link"
    else
      cp "$ubu_link" "/tmp/ubuautoscript_$i"
      echo -e "${GREEN} [i]${RESET} copying ISO $ubu_link"
    fi
  else
    echo -e "${GREEN} [i]${RESET} Downloading Ubuntu Version $ubuntu_version"
    wget "$ubu_link"
  fi
  mkdir source-files
  echo -e "${GREEN} [i]${RESET} Extracting ISO"
  xorriso -osirrox on -indev $iso --extract_boot_images source-files/bootpart -extract / source-files >/dev/null 2>&1
  echo -e "${GREEN} [+]${RESET} Generating folders"
  mkdir source-files/nocloud/
  cd source-files
  echo -e "${GREEN} [+]${RESET} Creating user-data "
  echo "I2Nsb3VkLWNvbmZpZwphdXRvaW5zdGFsbDoKICB2ZXJzaW9uOiAxCiAgYXB0OgogICAgZmFsbGJhY2s6IG9mZmxpbmUtaW5zdGFsbAogIGlkZW50aXR5OgoKCgogIG5ldHdvcms6CiAgICBldGhlcm5ldHM6CiAgICAgIGVuczE4OgogICAgICAgIGRoY3A0OiB0cnVlCiAgICB2ZXJzaW9uOiAyCiAgc3NoOgogICAgYWxsb3ctcHc6IHRydWUKICAgIGluc3RhbGwtc2VydmVyOiB0cnVlCiAgc3RvcmFnZToKICAgIGxheW91dDoKICAgICAgbmFtZTogbHZtCiAgbGF0ZS1jb21tYW5kczoKICAgIC0gbHZleHRlbmQgLWwgKzEwMCVGUkVFIC9kZXYvdWJ1bnR1LXZnL3VidW50dS1sdgogICAgLSByZXNpemUyZnMgL2Rldi9tYXBwZXIvdWJ1bnR1LS12Zy11YnVudHUtLWx2CiAgICAtIHBvd2Vyb2ZmCg==" | base64 --decode > nocloud/user-data
  sed -i "7s|$|    hostname: $hostname|" "$filename"
  sed -i "8s|$|    password: $encryptedp|" "$filename"
  sed -i "9s|$|    username: $username|" "$filename"
  chmod +r nocloud/user-data
  cat nocloud/user-data
  read -p "Press enter to continue (verify config looks correct): " null
  touch nocloud/meta-data
  echo -e "${GREEN} [+]${RESET} Appending grub.cfg"
  echo "c2V0IHRpbWVvdXQ9MAoKbG9hZGZvbnQgdW5pY29kZQoKc2V0IG1lbnVfY29sb3Jfbm9ybWFsPXdoaXRlL2JsYWNrCnNldCBtZW51X2NvbG9yX2hpZ2hsaWdodD1ibGFjay9saWdodC1ncmF5Cm1lbnVlbnRyeSAiQXV0b2luc3RhbGwgVWJ1bnR1IFNlcnZlciIgewogICAgc2V0IGdmeHBheWxvYWQ9a2VlcAogICAgbGludXggICAvY2FzcGVyL3ZtbGludXogcXVpZXQgYXV0b2luc3RhbGwgZHM9bm9jbG91ZFw7cz0vY2Ryb20vbm9jbG91ZC8gIC0tLQogICAgaW5pdHJkICAvY2FzcGVyL2luaXRyZAp9Cm1lbnVlbnRyeSAiVHJ5IG9yIEluc3RhbGwgVWJ1bnR1IFNlcnZlciIgewoJc2V0IGdmeHBheWxvYWQ9a2VlcAoJbGludXgJL2Nhc3Blci92bWxpbnV6ICAtLS0KCWluaXRyZAkvY2FzcGVyL2luaXRyZAp9Cm1lbnVlbnRyeSAiVWJ1bnR1IFNlcnZlciB3aXRoIHRoZSBIV0Uga2VybmVsIiB7CglzZXQgZ2Z4cGF5bG9hZD1rZWVwCglsaW51eAkvY2FzcGVyL2h3ZS12bWxpbnV6ICAtLS0KCWluaXRyZAkvY2FzcGVyL2h3ZS1pbml0cmQKfQpncnViX3BsYXRmb3JtCmlmIFsgIiRncnViX3BsYXRmb3JtIiA9ICJlZmkiIF07IHRoZW4KbWVudWVudHJ5ICdCb290IGZyb20gbmV4dCB2b2x1bWUnIHsKCWV4aXQgMQp9Cm1lbnVlbnRyeSAnVUVGSSBGaXJtd2FyZSBTZXR0aW5ncycgewoJZndzZXR1cAp9CmVsc2UKbWVudWVudHJ5ICdUZXN0IG1lbW9yeScgewoJbGludXgxNiAvYm9vdC9tZW10ZXN0ODYreDY0LmJpbgp9CmZpCg==" | base64 --decode | sudo tee boot/grub/grub.cfg >/dev/null
  echo -e "${GREEN} [+]${RESET} Repacking ISO"
  xorriso -as mkisofs -r -V "ubuntu-autoinstall" -J -boot-load-size 4 -boot-info-table -input-charset utf-8 -eltorito-alt-boot -b bootpart/eltorito_img1_bios.img -no-emul-boot -o "../ubuntu-$ubuntu_version-autoinstall.iso" . >/dev/null 2>&1
  sudo mv "../ubuntu-$ubuntu_version-autoinstall.iso" "$scriptloc/"
  echo -e "${GREEN} [✓]${RESET} Completed your packed iso is at $scriptloc/ubuntu-$ubuntu_version-autoinstall.iso"
  echo "Clean up temporary folders?"
  echo "  [a]  All created by this script"
  echo "  [y]  Only current temp folder"
  echo "  [n]  Skip cleanup"
  read -p "Choice: " cleanup_choice
  if [[ "$cleanup_choice" == "a" ]]; then
    echo "Removing /tmp/ubuautoscript_*"
    sudo rm -rf /tmp/ubuautoscript_*
  elif [[ "$cleanup_choice" == "y" ]]; then
    echo "Removing /tmp/ubuautoscript_$i" 
    sudo rm -rf "/tmp/ubuautoscript_$i"
  fi
else
  echo -e "${YELLOW} [x] Please run this script with sudo ${RESET}"
  exit 1
fi