# Stockage des documents du CRM (phase 4.2b)

Le CRM range chaque pièce envoyée (passeport, TIE, contrat…) dans un **bucket S3**, jamais sur le serveur. Ici : OVHcloud Object Storage, région GRA (UE).

## Pourquoi une racine Terraform à part (`envs/demo-data`)

- `envs/demo` décrit le **serveur jetable** : on l'éteint (`server_enabled=false`) après chaque démo.
- `envs/demo-data` décrit ce qui doit **survivre** au serveur : le bucket. State séparé (`demo-data/terraform.tfstate`) : aucune commande lancée dans `envs/demo` ne peut le supprimer.
- On l'applique **une seule fois**. La reconstruction chronométrée ne le touche pas.

## Mise en place (une fois)

Jeton d'API OVH : en créer un **neuf** (celui du bootstrap ne valait qu'un jour), avec la même URL que `docs/bootstrap.fr.md` §1 (droits limités à `/cloud/project/<PROJECT_ID>/*`), nom `tramelya-terraform-demo-data`, validité 1 jour. Symptôme d'un jeton expiré ou créé pour un autre projet : `403 Client::Forbidden: "This call has not been granted"` au premier `apply` (rien n'est créé ; refaire `plan` puis `apply` avec le nouveau jeton).

```bash
cd ~/dev/asesoria-infra/envs/demo-data
cp .env.example .env                  # remplir : state (AWS_*) + un jeton OVH NEUF (OVH_*), voir ci-dessous
cp terraform.tfvars.example terraform.tfvars   # remplir ovh_project_id
set -a; . ./.env; set +a
terraform init -backend-config=../../backend.hcl -backend-config="key=demo-data/terraform.tfstate"
terraform plan -out tfplan            # attendu : 4 ressources à créer (bucket, utilisateur, clé S3, policy)
terraform apply tfplan
```

Vérifier :

```bash
terraform output                      # la clé secrète apparaît masquée (sensitive)
terraform output -raw documents_secret_access_key | wc -c   # > 0 : la clé existe
```

Ranger `documents_access_key_id` et `documents_secret_access_key` dans le gestionnaire de mots de passe (entrée « tramelya – S3 documents démo »).

## Et ensuite

Ces valeurs vont dans le secret Kubernetes `acrm-s3`, chiffré par SOPS dans `asesoria-gitops` : `scripts/acrm-secrets.sh` les lit directement avec `terraform output` (voir `asesoria-gitops/docs/bootstrap.fr.md`, partie 4.2b).

## Points d'attention

- **Lexique** : *bucket* = « dossier racine » du stockage objet ; *objet* = un fichier ; *policy S3* = liste des actions autorisées, ici limitée à ce bucket (si la clé fuit, elle n'ouvre rien d'autre).
- **Données fictives** : ni versioning ni protection contre la suppression. Avant un pilote avec de vraies données : versioning, sauvegarde hors site, rétention (phase 5).
- **Orphelins** : après une reconstruction, la base repart vide ; les fichiers envoyés pendant la démo précédente restent dans le bucket. Pour faire le ménage : `aws s3 rm s3://tramelya-demo-documents --recursive --endpoint-url https://s3.gra.io.cloud.ovh.net` (avec les identifiants du bucket).
