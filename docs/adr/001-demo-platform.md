# ADR-001 — Plateforme de démonstration (phase 4.1)

- Statut : accepté, 2026-10-27
- Contexte : budget démo ≈ 25 €/mois, un seul opérateur, vitrine DevOps ; critère de la phase 4 : `terraform apply` recrée toute la plateforme.

## Décisions

1. **OVHcloud Public Cloud, région GRA11 (UE)**, instance Discovery `d2-8` à l'heure. OVH VPS écarté (cycle de vie non pilotable proprement par Terraform). Hetzner écarté (hausses 2026).
2. **Provider OpenStack pour le calcul et le réseau** (instance, groupe de sécurité), **provider OVH pour ce qui est propre au projet** (utilisateurs, stockage S3, policies S3). Raison : les groupes de sécurité n'existent que côté OpenStack ; c'est aussi la voie documentée par OVHcloud.
3. **Racine `bootstrap/` séparée** : bucket du state (versionné, chiffré, `prevent_destroy`), un utilisateur S3 limité par policy à ce seul bucket, un utilisateur OpenStack limité à `compute_operator`, `network_operator`, `network_security_operator`. Premier passage en state local, puis migration du state dans le bucket qu'il crée. Le jeton d'API OVH (droits limités à `/cloud/project/<id>/*`) ne sert qu'à cette racine.
4. **State distant S3 OVH**, verrou natif (`use_lockfile`, Terraform ≥ 1.10). Repli documenté si OVH ne gère pas l'écriture conditionnelle : verrou désactivé (un seul opérateur).
5. **Origine joignable uniquement via Cloudflare** : enregistrements proxifiés, 443 ouvert aux seules plages IPv4 de Cloudflare (`cloudflare_ip_ranges`), pas de port 80. SSL `full` en 4.1 (certificat auto-signé de Traefik), `strict` dès cert-manager (4.2).
6. **API Kubernetes jamais exposée** : pas de règle 6443, accès par tunnel SSH. Moins de surface d'attaque qu'un `tls-san` public + filtrage IP.
7. **Nœud jetable** : toute modification de cloud-init remplace l'instance ; aucune donnée sur le nœud tant que la base n'est pas sauvegardée hors site (phase 5). Interrupteur `server_enabled` pour ne payer le calcul que pendant les démos ; les zones DNS restent (pas de re-délégation).
8. **Pas de `terraform plan` en CI pour l'instant** : le dépôt est public et OVHcloud n'offre pas de fédération OIDC pour GitHub Actions ; y stocker des identifiants cloud n'est pas justifié pour une démo. Les plans se font en local ; à revoir avec un runner auto-hébergé ou des identifiants en lecture seule.
9. **Domaines** : `tramelya.es` (application) et `tramelya.com` (réservé). SPF `-all` + DMARC `reject` tant qu'aucun e-mail n'est envoyé depuis ces domaines.

10. **SSH ouvert à toutes les IP** (2026-10-29) : l'administrateur travaille sur un portable qui change de réseau ; restreindre le port 22 à une IP fixe le bloquerait. Compensations : authentification par clé uniquement (mot de passe et root refusés, `AllowUsers deploy`), fail2ban, mises à jour de sécurité automatiques. Risque résiduel : une faille d'OpenSSH avant correctif. Cible : **Cloudflare Tunnel + Access** (aucun port entrant, authentification par Cloudflare), à étudier en 4.2 ou lors du durcissement.

## Conséquences

- Deux jeux d'identifiants à gérer (OVH bootstrap, OpenStack + S3 pour les environnements), rangés dans le gestionnaire de mots de passe, chargés par `.env` ignoré par Git.
- Les plages IP de Cloudflare évoluent rarement ; un `apply` met le groupe de sécurité à jour.
- k3s s'installe par `get.k3s.io` sur un canal ; la mineure sera figée après validation (`k3s_channel`).
