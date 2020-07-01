test() {
  echo $#
  echo "${1}"
}

read -r -d '' VAR <<'EOF'
this
that

EOF

echo "${VAR}"
test "${VAR}"

