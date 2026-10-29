# Bootstrap de la plateforme de démo (phase 4.1)

Ordre fixe. Chaque bloc de commandes se lance depuis la racine du dépôt `~/dev/asesoria-infra`.
Les secrets vont **dans le gestionnaire de mots de passe**, puis dans des fichiers `.env` ignorés par Git. Jamais dans un `.tf`, un `.tfvars` ou un message.

## 0. Prérequis (Mac, une fois)

```bash
brew tap hashicorp/tap && brew install hashicorp/tap/terraform tflint
terraform version            # >= 1.10 (verrou natif du state S3)
ssh-keygen -t ed25519 -C "tramelya-admin" -f ~/.ssh/tramelya_ed25519
curl -4 -s ifconfig.me; echo  # ton IPv4 publique → admin_cidrs = ["<IP>/32"]
```

Dans la console OVHcloud : renommer le projet Public Cloud en `tramelya` (cosmétique) et copier son **identifiant** (32 caractères, en haut à gauche) → `<PROJECT_ID>` ci-dessous.

## 1. Jeton d'API OVH (droits limités au projet)

Ouvrir (remplacer `<PROJECT_ID>` aux 4 endroits) :

```
https://eu.api.ovh.com/createToken/?GET=/cloud/project/<PROJECT_ID>/*&POST=/cloud/project/<PROJECT_ID>/*&PUT=/cloud/project/<PROJECT_ID>/*&DELETE=/cloud/project/<PROJECT_ID>/*
```

Nom `tramelya-terraform-bootstrap`, validité **1 jour** (il ne sert qu'au bootstrap ; en recréer un si besoin). Ranger les 3 valeurs (application key, application secret, consumer key) dans le gestionnaire.

## 2. Bootstrap : bucket du state + utilisateurs limités

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars   # mettre ovh_project_id
cp .env.example .env                           # remplir OVH_* (laisser AWS_* vides)
set -a; . ./.env; set +a
terraform init
terraform apply                                # 5 ressources ; vérifier le plan avant « yes »
```

Si le nom `tramelya-tfstate` est déjà pris : changer `state_bucket_name` dans `terraform.tfvars` **et** `bucket` dans `../backend.hcl`.

Ranger les sorties dans le gestionnaire (une entrée « tramelya / terraform ») :

```bash
terraform output -raw state_access_key_id; echo
terraform output -raw state_secret_access_key; echo
terraform output -raw openstack_username; echo
terraform output -raw openstack_password; echo
```

Puis migrer le state local dans le bucket (il contient ces secrets : il ne doit pas rester sur le disque) :

```bash
# remplir AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY dans .env avec les deux premières sorties
set -a; . ./.env; set +a
mv backend.tf.disabled backend.tf
terraform init -migrate-state -backend-config=../backend.hcl -backend-config="key=bootstrap/terraform.tfstate"
terraform state list                           # doit lister les 5 ressources (lu depuis S3)
rm -f terraform.tfstate terraform.tfstate.backup
cd ..
```

Si `init` échoue sur le verrou (`use_lockfile`, erreur de type *PreconditionFailed* / *NotImplemented*) : mettre `use_lockfile = false` dans `backend.hcl`, relancer, et me le signaler (ADR-001 §4).

## 3. Jeton Cloudflare

Cloudflare → *My Profile* → *API Tokens* → *Create Custom Token* :

- Permissions : `Zone · Zone · Edit`, `Zone · Zone Settings · Edit`, `Zone · DNS · Edit`
- Account Resources : *Include* → ton compte ; Zone Resources : *Include* → *All zones from an account* → ton compte
- Nom `tramelya-terraform`, pas d'expiration ou 1 an

Récupérer aussi l'**Account ID** (page d'accueil du compte, colonne de droite, ou URL `dash.cloudflare.com/<ACCOUNT_ID>`).

Les zones `tramelya.com` et `tramelya.es` existaient déjà dans Cloudflare (créées à la main) : elles sont reprises par les blocs `import` de `envs/demo/imports.tf` au premier `apply`. Avant cela, supprimer à la main les entrées recopiées depuis OVH (page de parking `213.186.33.5`, `ftp`, TXT `1|…` / `3|welcome`, et pour `.es` tout le reste) : Terraform ne gère que les entrées qu'il a créées, et deux SPF sur un même domaine sont invalides.

## 4. Environnement de démo : serveur k3s + DNS

```bash
cd envs/demo
cp terraform.tfvars.example terraform.tfvars   # project id, account id CF, clé publique (cat ~/.ssh/tramelya_ed25519.pub), IP/32
cp .env.example .env                           # AWS_* (state), OS_USERNAME / OS_PASSWORD, CLOUDFLARE_API_TOKEN
set -a; . ./.env; set +a
terraform init -backend-config=../../backend.hcl -backend-config="key=demo/terraform.tfstate"
terraform plan -out tfplan                     # attendu : instance, groupe de sécurité + règles, 2 zones, réglages, enregistrements
time terraform apply tfplan                    # noter la durée (critère « < 1 h » de la phase 4)
terraform output
```

## 5. Délégation DNS chez OVH (une fois)

Pour **chaque** domaine, espace client OVH → *Noms de domaine* → `tramelya.es` → *Serveurs DNS* → *Modifier les serveurs DNS* → remplacer par les 2 serveurs de `terraform output name_servers` (ceux de ce domaine). Puis :

```bash
dig NS tramelya.es +short     # renvoie les serveurs Cloudflare (de quelques minutes à 24 h)
terraform apply -refresh-only # zone_status passe de "pending" à "active"
```

Activer **DNSSEC** plus tard (Cloudflare → DNS → Settings, puis l'enregistrement DS chez OVH) : non bloquant pour la démo.

## 6. Vérifications (≈ 5 min après l'apply, le temps de cloud-init)

```bash
IP=$(terraform output -raw server_ipv4)
ssh -i ~/.ssh/tramelya_ed25519 deploy@$IP 'cloud-init status --wait && sudo cat /var/log/tramelya-bootstrap.log'
```

Le journal doit montrer le nœud `Ready`, les pods système `Running` et `free -m` (**mémoire libre après k3s : à me donner**).

Contrôles de sécurité (tous doivent **échouer**) :

```bash
ssh -o PreferredAuthentications=password deploy@$IP   # Permission denied (publickey)
ssh -i ~/.ssh/tramelya_ed25519 root@$IP               # Permission denied
nc -vz -w 5 $IP 6443                                  # timeout : API Kubernetes non exposée
nc -vz -w 5 $IP 443                                   # timeout : 443 réservé à Cloudflare
```

⚠️ Si `nc … 443` ou `nc … 6443` **réussit**, le groupe de sécurité n'est pas appliqué au réseau public : `terraform apply -var server_enabled=false` et me prévenir avant toute autre chose.

Par Cloudflare (une fois la zone `active`) : `curl -sI https://app.tramelya.es` → réponse `404` de Traefik = chaîne Cloudflare → origine OK (aucune application déployée avant la 4.2).

## 7. kubectl depuis le Mac (tunnel SSH)

```bash
mkdir -p ~/.kube && ssh -i ~/.ssh/tramelya_ed25519 deploy@$IP 'sudo cat /etc/rancher/k3s/k3s.yaml' > ~/.kube/tramelya-demo.yaml && chmod 600 ~/.kube/tramelya-demo.yaml
ssh -i ~/.ssh/tramelya_ed25519 -N -L 6443:127.0.0.1:6443 deploy@$IP &   # tunnel en arrière-plan
KUBECONFIG=~/.kube/tramelya-demo.yaml kubectl get nodes,pods -A
```

## 8. Coûts : éteindre et rallumer

```bash
terraform apply -var server_enabled=false   # serveur + entrée app supprimés ; zones et state gardés (< 1 €/mois)
terraform apply                             # recrée tout le serveur (~5 min) pour une démo
```

Le crédit FREETRIAL (200 €) expire 1 mois après activation : au-delà, la facturation est réelle (d2-8 ≈ 20 €/mois s'il tourne en continu).

## Accès SSH depuis plusieurs lieux

Par défaut `admin_cidrs = ["0.0.0.0/0"]` : SSH accepté depuis n'importe quel réseau, mais uniquement avec la clé `~/.ssh/tramelya_ed25519` (ADR-001 §10). Pour restreindre à des IP fixes, mettre des `/32` dans `terraform.tfvars`, puis `terraform apply` (seules les règles SSH changent).
