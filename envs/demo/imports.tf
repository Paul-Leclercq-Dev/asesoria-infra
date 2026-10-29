# Zones créées à la main dans Cloudflare avant Terraform : on les reprend dans le
# state au lieu de les recréer (Cloudflare refuserait un doublon).
# Au premier `apply`, Terraform les importe ; ensuite ces blocs ne font plus rien
# et restent comme trace. Les Zone ID ne sont pas des secrets.
import {
  to = module.zone["tramelya.com"].cloudflare_zone.this
  id = "bcf10732bd3196dbb7129e6c225a45c3"
}

import {
  to = module.zone["tramelya.es"].cloudflare_zone.this
  id = "a622897c7c2a86ee421d975db2361f20"
}
