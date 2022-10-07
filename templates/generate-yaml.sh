# https://www.starkandwayne.com/blog/bashing-your-yaml/
export sample="Hello Yaml!"
export nats_machines="10.2.3.4"
export nats_username="nats"
export nats_password="password"
rm -f final.yml temp.yml
. <( echo "cat <<EOF >final.yml";
  cat generate-yaml-template.yml;
  echo "EOF";
)
cat final.yml
