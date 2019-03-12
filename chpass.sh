#!/bin/sh

print_help() {
  echo "chpass, version 0.1"
  echo "Usage: $0 -o OLD_PASS -n NEW_PASS [option] ..." >&2
  echo
  echo "  -h, --help            display this help and exit"
  echo "  -o, --old-passphrase  specify your old passphrase (e.g. "
  echo "                        correcthorsebatterystaple)"
  echo "  -n, --new-passphrase  specify your new passphrase (e.g. "
  echo "                        correcthorsebatterystaple)"
  echo
  echo "Options:"
  echo "  -u, --username        override user name (e.g. larry). Otherwise "
  echo "                        we assume user who called script."
  echo "  -l, --login           change login passphrase"
  echo "  -r, --root            change root's passphrase"
  echo "  -s, --ssh-key         specify your SSH key to change your "
  echo "                        passphrase of (e.g. ~/.ssh/id_ed25519)"
  echo "  -L, --luks-gpg-key    specify your LUKS GPG key in /boot to change "
  echo "                        your passphrase of (e.g. /boot/root.gpg)"
  echo "  -g, --gpg-key-id      specify your GPG key ID to change your "
  echo "                        passphrase of (e.g. "
  echo "                        26D3D565A520CC894E457D0F5922172F920C075A). "
  echo "                        does not work with --old-passphrase, or "
  echo "                        --new-passphrase and will prompt for both."
  echo
  exit 0
}

check_sudo() {
  if [ `whoami` != root ]; then
    echo "Please run this script using sudo. Exiting..."
    exit 1
  fi
}

get_args() {
  while [[ "$1" ]]; do
    case "$1" in
      -h|--help) print_help ;;
      -o|--old-passphrase) OLD_PASSWD="${2}" ;;
      -n|--new-passphrase) NEW_PASSWD="${2}" ;;
      -u|--username) USER="${2}" ;;
      -l|--login) LOGIN="1" ;;
      -r|--root) ROOT="1" ;;
      -s|--ssh-key) SSH_KEY=$(readlink -m ${2}) ;;
      -L|--luks-gpg-key) LUKS_GPG_KEY=$(readlink -m ${2}) ;;
      -g|--gpg-key-id) GPG_KEY_ID="{2}" ;;
    esac
    shift
  done
}

get_vars() {
  # Terminal colours
  GREEN='\033[0;32m'
  BLUE='\033[0;34m'
  MAGENTA='\033[0;35m'
  LGREEN='\033[1;32m'
  LRED='\033[1;31m'
  YELLOW='\033[1;33m'
  NC='\033[0m'

  # Notification prefix
  NOTIFY_PREFIX=">>> Setting new passwd for:"
}

test_args() {
  if [ ! -n "${OLD_PASSWD}" ]; then
    echo "-o|--old-passphrase no set. Exiting..".
    exit 1
  fi

  if [ ! -n "${NEW_PASSWD}" ]; then
    echo "-n|--new-passphrase no set. Exiting..".
    exit 1
  fi

  if [ ! -n "${USER}" ]; then
    USER="${SUDO_USER:-${USER}}"
  fi
}

user_passwd() {
  if ! echo "${USER}:${NEW_PASSWD}" | chpasswd; then
    echo -e "[${LRED}FAILED${NC}]: did you run as root?"
  fi
}

root_passwd() {
  if ! echo "root:${NEW_PASSWD}" | chpasswd; then
    echo -e "[${LRED}FAILED${NC}]: did you run as root?"
  fi
}

ssh_key() {
  if ! ssh-keygen -q -p -P "${NEW_PASSWD}" -N "${NEW_PASSWD}" -f "${SSH_KEY}" >/dev/null 2>&1; then
    if ! ssh-keygen -q -p -P "${OLD_PASSWD}" -N "${NEW_PASSWD}" -f "${SSH_KEY}" >/dev/null 2>&1; then
      echo -e "[${LRED}FAILED${NC}]: is OLD_PASSWD correct?"
    fi
  fi
}

luks_gpg_key() {
  mount /boot 2>/dev/null
  if ! gpg --quiet --decrypt --batch --passphrase "${NEW_PASSWD}" "${LUKS_GPG_KEY}" >/dev/null 2>&1; then
    echo $?
    if gpg --quiet --decrypt --batch --passphrase "${OLD_PASSWD}" "/boot/${LUKS_GPG_KEY}" >/dev/null 2>&1; then
    cp "/boot/${LUKS_GPG_KEY}" "/root/old-root.gpg"
      if gpg --quiet --decrypt --batch --passphrase "${OLD_PASSWD}" "/root/old-root.gpg" | gpg --quiet --batch --symmetric --passphrase "${NEW_PASSWD}" -o "/root/new-root.gpg" > /dev/null 2>&1; then
        if gpg --quiet --batch --decrypt --no-symkey-cache --passphrase "${NEW_PASSWD}" "/root/new-root.gpg" > /dev/null 2>&1; then
          mv "/root/new-root.gpg" "/boot/${LUKS_GPG_KEY}" && rm "/root/old-root.gpg" 2>/dev/null
        else
          echo -e "[${LRED}FAILED${NC}]: NEW_PASSWD is used to create new LUKS_GPG_KEY, but could not be used to decrypt new LUKS_GPG_KEY??? Exiting..."
          exit 1
        fi
      else
        echo -e "[${LRED}FAILED${NC}]: OLD_PASSWD is correct, but could not create new LUKS_GPG_KEY with NEW_PASSWD? Exiting..."
        exit 1
      fi
    else
      echo -e "[${LRED}FAILED${NC}]: is OLD_PASSWD correct? Exiting..."
      exit 1
    fi
  fi
  umount /boot 2>/dev/null
}

gpg_key() {
  if ! gpg --homedir "/home/${USER}/.gnupg" --batch --passwd "${GPG_KEY_ID}"; then
    echo -e "[${LRED}FAILED${NC}]: could not change GPG key passphrase. Exiting..."
    exit 1
  fi
}

get_args "$@"
get_vars
test_args
check_sudo

if [ -n "${LOGIN}" ]; then
  echo -n '>>> Changing user passwd .................................. '
  if user_passwd ; then
    echo -e "${BLUE}[${NC} ${LGREEN}ok${NC} ${BLUE}]${NC}"
  fi
fi

if [[ "${ROOT}" -eq "1" ]]; then
  echo -n '>>> Changing root passwd .................................. '
  if root_passwd ; then
    echo -e "${BLUE}[${NC} ${LGREEN}ok${NC} ${BLUE}]${NC}"
  fi
fi

if [ -n "${SSH_KEY}" ]; then
  echo -n '>>> Changing SSH key passwd ............................... '
  if ssh_key ; then
    echo -e "${BLUE}[${NC} ${LGREEN}ok${NC} ${BLUE}]${NC}"
  fi
fi

if [ -n "${LUKS_GPG_KEY}" ]; then
  echo -n '>>> Changing LUKS key passwd .............................. '
  if luks_gpg_key ; then
    echo -e "${BLUE}[${NC} ${LGREEN}ok${NC} ${BLUE}]${NC}"
  fi
fi

if [ -n "${GPG_KEY_ID}" ]; then
  echo
  echo '--- Changing GPG key passwd (manual procedure) --- '
  echo
  gpg_key
fi

echo
echo "Changing passwords complete."
