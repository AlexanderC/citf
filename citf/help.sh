main() {
    echo -e "CI BUilder helper + Terraform + AWS update
    citf <module> [args..]
MODULES:"
    find $PREFIX -type f -iname "*.sh" -print | sed 's/.*\///; s/\.sh//'
}