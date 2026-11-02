# E-mail `contact@tramelya.com` (phase 4.1b)

**Principe** : Cloudflare Email Routing est un service de réexpédition. Les e-mails
envoyés à `contact@tramelya.com` arrivent sur les serveurs de courrier (MX) de
Cloudflare, qui les transfèrent vers une boîte existante (`contact_forward_to`).
Gratuit, aucune boîte à héberger. Il ne sait **pas envoyer** : répondre en tant que
`contact@` demandera un SMTP externe (plus tard, au moment de prospecter).

Code : `envs/demo/email.tf` ; décision : ADR-001 §12.

## 1. Jeton Cloudflare : deux permissions de plus (une fois)

Cloudflare → *My Profile* → *API Tokens* → `tramelya-terraform` → *Edit* → ajouter :

- `Account · Email Routing Addresses · Edit` (la boîte de destination appartient au compte)
- `Zone · Email Routing Rules · Edit` (activation du routage et règles de la zone)

Le jeton garde sa valeur : rien à changer dans `.env`.

## 2. Retirer les entrées mail d'OVH sur `tramelya.com` (une fois, à la main)

Cloudflare → `tramelya.com` → *DNS* → *Records* : supprimer les **MX** (`mx*.mail.ovh.net`),
le **TXT `v=spf1 …`** d'OVH et, s'il existe, le **TXT `_dmarc`**.
Pourquoi : Cloudflare refuse d'activer le routage tant que d'autres MX existent
(erreur 2008), il ajoute son SPF seulement si aucun n'existe, et Terraform crée
désormais le DMARC (deux DMARC = aucun n'est valide).
Effet : pendant les quelques minutes jusqu'à l'`apply`, un e-mail vers `tramelya.com`
est mis en attente par l'expéditeur, puis réessayé.

## 3. Appliquer

```bash
cd envs/demo
# ajouter dans terraform.tfvars :  contact_forward_to = "ta.boite@exemple.com"
set -a; . ./.env; set +a
terraform plan -out tfplan    # attendu : 4 to add (routage, adresse, règle, DMARC), 0 to change, 0 to destroy
terraform apply tfplan
terraform output email_routing_status       # attendu : "ready"
```

Si l'`apply` échoue sur `cloudflare_email_routing_rule.contact` avec un message de
vérification de l'adresse : faire l'étape 4, puis relancer `plan` / `apply`
(Terraform reprend où il s'était arrêté). Une erreur 403 = permission du §1 manquante.

## 4. Vérifier la boîte de destination (une fois)

Cloudflare envoie à `contact_forward_to` un e-mail « Verify your email address ».
Cliquer le lien, puis :

```bash
terraform apply -refresh-only   # met à jour le state
terraform output contact_forward_verified   # une date (null = pas encore vérifiée)
```

Tant que la boîte n'est pas vérifiée, la règle existe mais ne transfère rien.

## 5. Test de bout en bout

```bash
dig MX tramelya.com +short    # route1/2/3.mx.cloudflare.net
dig TXT tramelya.com +short   # "v=spf1 include:_spf.mx.cloudflare.net ~all"
dig TXT _dmarc.tramelya.com +short
```

Depuis une **autre** adresse que la boîte de destination (Gmail ignore un e-mail
qu'on s'envoie à soi-même), écrire à `contact@tramelya.com` : il arrive en moins
d'une minute. Une adresse inventée (`xyz@tramelya.com`) est refusée (pas de catch-all).
Journal des transferts : Cloudflare → `tramelya.com` → *Email* → *Email Routing* → *Activity log*.

## Revenir en arrière

`terraform destroy -target=cloudflare_email_routing_rule.contact -target=cloudflare_email_routing_dns.mail`
désactive le routage et retire les MX, SPF et DKIM de Cloudflare. L'adresse de destination
reste vérifiée dans le compte.
