cat <<EOF >my_profile.sh
export CHARSET=\${CHARSET:-UTF-8}
export LANG=\${LANG:-C.UTF-8}
export LC_COLLATE=\${LC_COLLATE:-C}
export TERM=xterm-256color
export COLORTERM=truecolor
EOF

mv my_profile.sh /etc/profile.d/my_profile.sh