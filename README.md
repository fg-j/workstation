# Ephemeral workstation setup

Usage

# To create a pairing ready vm

```
setup.sh [OPTIONS]

OPTIONS
  --help, -h                                                prints the command usage
  --name, -n <name of vm>                                   specify the name of this workstation
  --gcp-project, -p <gcp-project>                           name of gcp project to place the vm in
  --service-account-json, -s <path/to/service/account/json> path to gcp service account json to authenticate with
```

```bash
$ ./setup.sh -n my-vm -p my-gcp-project -s /tmp/my-gcp-service-account-key.json
```

# To see what vms are in your pool

```
list.sh [OPTIONS]

OPTIONS
  --help, -h                                                prints the command usage
  --service-account-json, -s <path/to/service/account/json> path to gcp service account json to authenticate with
```

```bash
$ ./list.sh -s /tmp/my-gcp-service-account-key.json
```

# To log onto any vm in your pool

```
ssh.sh [OPTIONS]

OPTIONS
  --help, -h                                                prints the command usage
  --name, -n <name of vm>                                   specify the name of this workstation
  --service-account-json, -s <path/to/service/account/json> path to gcp service account json to authenticate with
```

```bash
$ ./ssh.sh -n my-vm -s /tmp/my-gcp-service-account-key.json
```

