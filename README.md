# Ephemeral workstation setup

Usage

### Write your tfvars

```bash
$ cat <<EOF > terraform/terraform.tfvars
vm_name="some-name"
project="my-gcp-project"
service_account_key="my-service-account-key-json"
EOF
```

### Create your vm
```bash
$ ./setup.sh
```

### Use your vm
```bash
$ pushd terraform
$   ssh ubuntu@"$(terraform output vm_ip)" -i /tmp/key
```
