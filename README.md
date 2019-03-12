# chpass
A script for own convenience to change all my passwords. It changes the passphrases of my current user, root, my ssh key, my luks gpg key, and my personal gpg key. Prefix a space before running this command to avoid storing your passwords in your shell history.

## Full disclosure
I'm not a developer by any means, and you may find this repository a comical attempt to automate installing Gentoo on a Raspberry Pi 2/3. And you're probably right, so feel free to:

1. Not use it;
2. Show me how to make it better (you are encouraged!).

## Usage
```
$ ./chpass.sh -h 
chpass, version 0.1
Usage: ./chpass.sh -o OLD_PASS -n NEW_PASS [option] ...

  -h, --help            display this help and exit
  -o, --old-passphrase  specify your old passphrase (e.g. 
                        correcthorsebatterystaple)
  -n, --new-passphrase  specify your new passphrase (e.g. 
                        correcthorsebatterystaple)

Options:
  -u, --username        override user name (e.g. larry). Otherwise 
                        we assume user who called script.
  -l, --login           change login passphrase
  -r, --root            change root's passphrase
  -s, --ssh-key         specify your SSH key to change your 
                        passphrase of (e.g. ~/.ssh/id_ed25519)
  -L, --luks-gpg-key    specify your LUKS GPG key in /boot to change 
                        your passphrase of (e.g. /boot/root.gpg)
  -g, --gpg-key-id      specify your GPG key ID to change your 
                        passphrase of (e.g. 
                        26D3D565A520CC894E457D0F5922172F920C075A). 
                        does not work with --old-passphrase, or 
                        --new-passphrase and will prompt for both.

```

## Example
```
$  sudo ./chpass.sh -o 'oldpass' -n 'newpass' -l -r -s ~/.ssh/id_ed25519 \
  -L /boot/root.gpg

>>> Changing user passwd .................................. [ ok ]
>>> Changing root passwd .................................. [ ok ]
>>> Changing SSH key passwd ............................... [ ok ]
>>> Changing LUKS key passwd .............................. [ ok ]

Changing passwords complete.

```

# Dependencies
1. coreutils (sys-apps/coreutils);
2. gpg (app-crypt/gnupg);
3. openssh (net-misc/openssh);
4. shadow (sys-apps/shadow).

# To do
1. Figure out a way to change personal GPG key non-interactively. Couldn't get it to work with gpg itself, gpg-agent (pinentry loopback), nor expect.
